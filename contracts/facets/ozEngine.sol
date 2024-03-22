// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {
    AppStorage, 
    AmountsIn, 
    AmountsOut, 
    Asset,
    Action
} from "../AppStorage.sol";
import {FixedPointMathLib} from "../libraries/FixedPointMathLib.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IVault, IAsset, IPool} from "../interfaces/IBalancer.sol";
import {IPool, IQueries} from "../interfaces/IBalancer.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {ozIToken} from "../interfaces/ozIToken.sol";
import {
    IRocketStorage, 
    IRocketDepositPool, 
    IRocketVault,
    IRocketDAOProtocolSettingsDeposit
} from "../interfaces/IRocketPool.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../Errors.sol";
import {Modifiers} from "../Modifiers.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";


contract ozEngine is Modifiers { 

    using TransferHelper for address;
    using FixedPointMathLib for uint;
    using Helpers for uint;
    using SafeERC20 for IERC20;
    

    //----------

    function useOZL(
        address tokenOut_,
        address receiver_,
        uint amountInLsd_,
        uint[] memory minAmountsOut_
    ) external returns(uint) {
        return _checkPauseAndSwap(
            s.rETH,
            tokenOut_,
            receiver_,
            amountInLsd_,
            minAmountsOut_,
            Action.OZL_IN
        );
    }


    function useUnderlying( 
        address underlying_, 
        address owner_,
        AmountsIn memory amounts_
    ) external onlyOzToken returns(uint) { 
        uint amountIn = amounts_.amountIn;

        /**
         * minAmountsOut[0] - minWethOut
         * minAmountsOut[1] - minRethOut
         */
        uint[] memory minAmountsOut = amounts_.minAmountsOut;
        
        IERC20(underlying_).safeTransferFrom(owner_, address(this), amountIn);

        //Swaps underlying to WETH in Uniswap
        uint amountOut = _swapUni(
            underlying_, 
            s.WETH, 
            address(this),
            amountIn, 
            minAmountsOut[0]
        );

        if (_checkRocketCapacity(amountOut)) {
            IWETH(s.WETH).withdraw(amountOut);
            address rocketDepositPool = IRocketStorage(s.rocketPoolStorage).getAddress(s.rocketDepositPoolID); //Try here to store the depositPool with SSTORE2-3 (if it's cheaper in terms of gas) ***
            
            //Simplify this
            uint preBalance = IERC20(s.rETH).balanceOf(address(this));
            IRocketDepositPool(rocketDepositPool).deposit{value: amountOut}();
            uint postBalance = IERC20(s.rETH).balanceOf(address(this));

            return postBalance - preBalance;
        
        } else {
            return _checkPauseAndSwap(
                s.WETH, 
                s.rETH, 
                address(this),
                amountOut,
                minAmountsOut,
                Action.OZ_IN
            );
        }
    }


    function useOzTokens(
        address owner_,
        bytes memory data_
    ) external onlyOzToken returns(uint, uint) {
        (AmountsOut memory amts, address receiver) = abi.decode(data_, (AmountsOut, address));
        
        /**
         * minAmountsOut[0] = minAmountOutWeth
         * minAmountsOut[1] = minAmountOutUnderlying
         */
        uint[] memory minAmountsOut = amts.minAmountsOut;
        uint amountInReth = amts.amountInReth;
        
        msg.sender.safeTransferFrom(owner_, address(this), amts.ozAmountIn);

        //Swap rETH to WETH
        uint amountOut = _checkPauseAndSwap(
            s.rETH,
            s.WETH,
            address(this), 
            amountInReth,
            minAmountsOut,
            Action.OZ_OUT
        );

        //swap WETH to underlying
        amountOut = _swapUni(
            s.WETH,
            ozIToken(msg.sender).asset(),
            receiver,
            amountOut,
            minAmountsOut[1]
        );

        return (amountInReth, amountOut);
    }

    //Sends the OZL tokens from the owner back to the ozDiamond to be 
    //used once again in a new distribution campaign
    function recicleOZL(
        address owner_,
        address ozl_,
        uint amountIn_
    ) external {
        IERC20(ozl_).safeTransferFrom(owner_, address(this), amountIn_);
        ozIDiamond(address(this)).modifySupply(amountIn_);
    }


    /**
    * HELPERS 
    */
    function _checkPauseAndSwap(
        address tokenIn_,
        address tokenOut_,
        address receiver_,
        uint amountIn_,
        uint[] memory minAmountsOut_,
        Action type_
    ) private returns(uint amountOut) {

        (address tokenOutInternal, uint minAmountOutFirstLeg) = 
            _triageInternalVars(type_, minAmountsOut_, tokenOut_);

        (bool paused,,) = IPool(s.rEthWethPoolBalancer).getPausedState(); 

        if (paused) {
            amountOut = _swapUni(
                tokenIn_,
                tokenOutInternal,
                address(this),
                amountIn_,
                minAmountOutFirstLeg
            );
        } else {
            amountOut = _swapBalancer(
                tokenIn_,
                tokenOutInternal,
                amountIn_,
                minAmountOutFirstLeg
            );
        }

        if (type_ == Action.OZL_IN) {
            if (tokenOut_ == s.WETH) { 
                IERC20(s.WETH).safeTransfer(receiver_, amountOut);
            } else {
                amountOut = _swapUni(
                    s.WETH,
                    tokenOut_,
                    receiver_,
                    amountOut,
                    minAmountsOut_[1]
                );
            }
        }
    }


    function _swapUni(
        address tokenIn_,
        address tokenOut_,
        address receiver_,
        uint amountIn_, 
        uint minAmountOut_
    ) private returns(uint) {
        IERC20(tokenIn_).safeApprove(s.swapRouterUni, amountIn_);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({ 
                tokenIn: tokenIn_,
                tokenOut: tokenOut_, 
                fee: s.uniFee, 
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minAmountOut_.formatMinOut(tokenOut_), 
                sqrtPriceLimitX96: 0
            });

        try ISwapRouter(s.swapRouterUni).exactInputSingle(params) returns(uint amountOut) { 
            return amountOut;
        } catch Error(string memory reason) {
            revert OZError01(reason);
        }
    }


    function _swapBalancer( 
        address tokenIn_, 
        address tokenOut_, 
        uint amountIn_,
        uint minAmountOut_
    ) private returns(uint amountOut) {

        console.log('');
        console.log('bal: ', IERC20(tokenIn_).balanceOf(address(this)));
        console.log('bal2: ', IERC20(tokenIn_).balanceOf(msg.sender));
        console.log('amountIn_: ', amountIn_);
        console.log('minAmountOut_: ', minAmountOut_);
        console.log('tokenIn_: ', tokenIn_);
        
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: IPool(s.rEthWethPoolBalancer).getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(tokenIn_),
            assetOut: IAsset(tokenOut_),
            amount: amountIn_,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false, 
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        IERC20(tokenIn_).safeApprove(s.vaultBalancer, singleSwap.amount);
        amountOut = _executeSwap(singleSwap, funds, minAmountOut_, block.timestamp);
    }


    function _executeSwap(
        IVault.SingleSwap memory singleSwap_,
        IVault.FundManagement memory funds_,
        uint minAmountOut_,
        uint blockStamp_
    ) private returns(uint) 
    {
        try IVault(s.vaultBalancer).swap(singleSwap_, funds_, minAmountOut_, blockStamp_) returns(uint amountOut) {
            if (amountOut == 0) revert OZError02();
            return amountOut;
        } catch Error(string memory reason) {
            if (Helpers.compareStrings(reason, 'BAL#507')) {
                revert OZError20();
            } else {
                revert OZError21(reason);
            }
        }
    }


    function _checkRocketCapacity(uint amountIn_) private view returns(bool) {
        uint poolBalance = IRocketVault(s.rocketVault).balanceOf('rocketDepositPool');
        uint capacityNeeded = poolBalance + amountIn_;

        IRocketDAOProtocolSettingsDeposit settingsDeposit = IRocketDAOProtocolSettingsDeposit(IRocketStorage(s.rocketPoolStorage).getAddress(s.rocketDAOProtocolSettingsDepositID));
        uint maxDepositSize = settingsDeposit.getMaximumDepositPoolSize();

        return capacityNeeded < maxDepositSize;
    }   


    function _triageInternalVars(
        Action type_, 
        uint[] memory minAmountsOut_,
        address tokenOut_
    ) private view returns(
        address tokenOutInternal, 
        uint minAmountOutFirstLeg
    ) {
        if (type_ == Action.OZL_IN) {
            tokenOutInternal = s.WETH;
            minAmountOutFirstLeg = minAmountsOut_[0];
        } else if (type_ == Action.OZ_IN) {
            tokenOutInternal = tokenOut_;
            minAmountOutFirstLeg = minAmountsOut_[1];
        } else if (type_ == Action.OZ_OUT) {
            tokenOutInternal = tokenOut_;
            minAmountOutFirstLeg = minAmountsOut_[0];
        }
    }
}