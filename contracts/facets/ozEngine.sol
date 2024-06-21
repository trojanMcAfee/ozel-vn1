// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


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
import {IAave} from "../interfaces/IAave.sol";

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
        address stable_, 
        address owner_,
        AmountsIn memory amts_,
        bool isETH_
    ) external payable onlyOzToken returns(uint, uint) { 
        uint amountInStable = amts_.amountInStable;
        uint amountOutRETH;

        /**
         * minAmountsOut[0] - minWethOut
         * minAmountsOut[1] - minRethOut
         */
        // uint[] memory minAmountsOut;
        // uint[] memory minAmountsOut = amts_.minAmountsOutRETH;
        
        IERC20(stable_).safeTransferFrom(owner_, address(this), amountInStable);

        //Swaps underlying to WETH in Uniswap
        // uint amountOut = _swapUni(
        //     underlying_, 
        //     s.WETH, 
        //     address(this),
        //     amountIn, 
        //     minAmountsOut[0]
        // );

        if (isETH_) IWETH(s.WETH).deposit{value: msg.value}();
        uint amountInWETH = IWETH(s.WETH).balanceOf(address(this));


        if (_checkRocketCapacity(amountInWETH)) { //haven't done this for ETH = true / _checkRocketCapacity(amountOut)
            IWETH(s.WETH).withdraw(amountInWETH);
            address rocketDepositPool = IRocketStorage(s.rocketPoolStorage).getAddress(s.rocketDepositPoolID); //Try here to store the depositPool with SSTORE2-3 (if it's cheaper in terms of gas) ***
            
            //Simplify this
            uint preBalance = IERC20(s.rETH).balanceOf(address(this));
            IRocketDepositPool(rocketDepositPool).deposit{value: amountInWETH}();
            uint postBalance = IERC20(s.rETH).balanceOf(address(this));

            amountOutRETH = postBalance - preBalance;
        
        } else {
            //*********/
            uint[] memory minAmountsOut = new uint[](2);
            minAmountsOut[0] = amts_.minAmountOutRETH;
            //*********/ <--- put this later on the offchain call's data to mint()

            amountOutRETH = _checkPauseAndSwap2(
                s.WETH, 
                s.rETH, 
                address(this),
                amountInWETH,
                minAmountsOut,
                Action.OZ_IN //put an action that represents indifference, cross-check against _checkPauseAndSwap2() def
            );
        }

        uint amountOutAUSDC = _lendToAave(amountInStable, stable_);

        return (amountOutRETH, amountOutAUSDC);
    }

    //--------------
    function _lendToAave(uint amountInStable_, address stable_) private returns(uint) {
        address poolAave = IAave(s.poolProviderAave).getPool();
        IERC20(stable_).approve(poolAave, amountInStable_);

        IAave(poolAave).supply(stable_, amountInStable_, address(this), 0);

        return amountInStable_;
    }


    // function _hedgeLST(uint amountInLst_) private {
    //     //deposit LST in aave
    //     IERC20(s.rETH).approve(s.poolAave, amountInLst_);
    //     IAave(s.poolAave).supply(s.rETH, amountInLst_, address(this), 0);

        // uint x = IERC20(0xCc9EE9483f662091a1de4795249E24aC0aC2630f).balanceOf(address(this));

    //     console.log('amountInLst_: ', amountInLst_);
    //     console.log('arETH bal this: ', x);
    //     console.log('');

    //     //borrow LST
    //     console.log('rETH bal pre borrow - 0: ', IERC20(s.rETH).balanceOf(address(this)));
    //     console.log('eMode of ozDiamond - 1: ', IAave(s.poolAave).getUserEMode(address(this)));

    //     IAave(s.poolAave).borrow(s.rETH, _getEmodeLTV(amountInLst_), 2, 0, address(this));
    //     console.log('rETH bal post borrow - not 0: ', IERC20(s.rETH).balanceOf(address(this)));
    //     console.log('');

    //     (
    //         uint256 totalCollateralBase,
    //         uint256 totalDebtBase,
    //         uint256 availableBorrowsBase,
    //         uint256 currentLiquidationThreshold,
    //         uint256 ltv,
    //         uint256 healthFactor
    //     ) = IAave(s.poolAave).getUserAccountData(address(this));

    //     console.log('totalCollateralBase: ', totalCollateralBase);
    //     console.log('totalDebtBase: ', totalDebtBase);
    //     console.log('availableBorrowsBase: ', availableBorrowsBase);
    //     console.log('currentLiquidationThreshold: ', currentLiquidationThreshold);
    //     console.log('ltv: ', ltv);
    //     console.log('healthFactor: ', healthFactor);

    //     //sell LST and do accounting with the funds
    //     //modify _setValuePerOzToken
    // }

    // function _getEmodeLTV(uint amountInLst_) private returns(uint) {
    //     return uint(9000).mulDivDown(amountInLst_, 10_000);
    // }
    //---------------


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


    function _checkPauseAndSwap2(
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
                tokenOutInternal, //tokenOut_
                address(this),
                amountIn_,
                minAmountOutFirstLeg
            );
        } else {   
            amountOut = _swapBalancer(
                tokenIn_,
                tokenOutInternal, //tokenOut_
                amountIn_,
                minAmountOutFirstLeg
            );
        }

        if (type_ == Action.OZL_IN || type_ == Action.REBASE) {
            if (tokenOut_ == s.WETH) { 
                IERC20(s.WETH).safeTransfer(receiver_, amountOut);
            } else {
                amountOut = _swapUni(
                    s.WETH,
                    tokenOut_,
                    receiver_,
                    amountOut,
                    // minAmountOut_
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


    function executeRebaseSwap() external returns(bool) { //onlyAuth
        //put the 7 days check
        if (s.rewardsStartTime + s.EPOCH < block.timestamp) return false;

        uint rateRETHETH = Helpers.rETH_ETH(ozIDiamond(address(this)));
        console.log('rateRETHETH: ', rateRETHETH);
        if (rateRETHETH <= s.lastRebasePriceRETHETH) return false;

        uint sysBalanceRETH = IERC20Permit(s.rETH).balanceOf(address(this));
        console.log('sysBalanceRETH - pre swap: ', sysBalanceRETH);

        uint sysBalanceConvertedETH = sysBalanceRETH.mulDivDown(rateRETHETH, 1 ether);
        console.log('sysBalanceConvertedETH: ', sysBalanceConvertedETH);
        console.log('s.sysBalanceETH: ', s.sysBalanceETH);

        uint rewardsETH = sysBalanceConvertedETH - s.sysBalanceETH;
        console.log('rewardsETH: ', rewardsETH);

        uint amountToSwapRETH = rewardsETH.mulDivDown(1 ether, rateRETHETH);
        console.log('amountToSwapRETH: ', amountToSwapRETH);

        //******/
        uint[] memory minAmountsOut = new uint[](2); //<--- given by a keeper
        //******/

        console.log('');
        console.log('USDC bal diamond - pre swap: ', IERC20Permit(s.USDC).balanceOf(address(this)));

        console.log('');
        console.log('**** SWAP ****');
        console.log('');

        uint amountOutUSDC =_checkPauseAndSwap2(
            s.rETH,
            s.USDC,
            address(this),
            amountToSwapRETH,
            minAmountsOut, //<----- has to be given by a keeper (one for rETH<>WETH - other WETH<>USDC)
            Action.REBASE 
        );

        s.stakingRewardsUSDC += amountOutUSDC;
        s.lastRebasePriceRETHETH = rateRETHETH;
        s.rewardsStartTime = block.timestamp;

        console.log('stakingRewardsUSDC: ', s.stakingRewardsUSDC);
        console.log('lastRebasePriceRETHETH: ', s.lastRebasePriceRETHETH);
        console.log('sysBalanceRETH - post swap: ', IERC20Permit(s.rETH).balanceOf(address(this)));
        console.log('USDC bal diamond - post swap: ', IERC20Permit(s.USDC).balanceOf(address(this)));

        return true;

        //emit rebase event here
    }


    function _checkRocketCapacity(uint amountIn_) private view returns(bool) {
        uint poolBalance = IRocketVault(s.rocketVault).balanceOf('rocketDepositPool');
        uint capacityNeeded = poolBalance + amountIn_;

        IRocketDAOProtocolSettingsDeposit settingsDeposit = IRocketDAOProtocolSettingsDeposit(IRocketStorage(s.rocketPoolStorage).getAddress(s.rocketDAOProtocolSettingsDepositID));
        uint maxDepositSize = settingsDeposit.getMaximumDepositPoolSize();

        return capacityNeeded < maxDepositSize;
    }   


    // function _triageTokenOut(
    //     Action type_, 
    //     address tokenOut_
    // ) private view returns(address tokenOutInternal) {
    //     if (tokenOut_ == s.USDC) {
    //         tokenOutInternal = s.WETH;
    //     } else if (tokenOut_ == s.rETH) {
    //         tokenOutInternal = s.rETH;
    //     }
    // }


    function _triageInternalVars(
        Action type_, 
        uint[] memory minAmountsOut_,
        address tokenOut_
    ) private view returns(
        address tokenOutInternal, 
        uint minAmountOutFirstLeg
    ) {
        if (type_ == Action.OZL_IN || type_ == Action.REBASE) {
            tokenOutInternal = s.WETH;
            minAmountOutFirstLeg = minAmountsOut_[0];
        } else if (type_ == Action.OZ_IN) {
            tokenOutInternal = tokenOut_;
            minAmountOutFirstLeg = minAmountsOut_[0]; //fix this since no sense all minAmountsOut[0]
        } else if (type_ == Action.OZ_OUT) {
            tokenOutInternal = tokenOut_;
            minAmountOutFirstLeg = minAmountsOut_[0]; //minAmountsOut arr is used by keepers call only so far
        } 
    }
}