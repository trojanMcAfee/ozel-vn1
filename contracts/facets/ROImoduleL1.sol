// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import "../../lib/forge-std/src/interfaces/IERC20.sol"; 
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {
    AppStorage, 
    AmountsIn, 
    AmountsOut, 
    Asset
} from "../AppStorage.sol";
// import "solady/src/utils/FixedPointMathLib.sol";
import {FixedPointMathLib} from "../libraries/FixedPointMathLib.sol";
import {IWETH} from "../interfaces/IWETH.sol";
// import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
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

import "forge-std/console.sol";


error TokenInNotValid(address token);
error InvalidBalancerSwap();

error OZError01(string errorMsg);


contract ROImoduleL1 {

    using TransferHelper for address;
    using FixedPointMathLib for uint;
  
    AppStorage internal s;


    function useUnderlying( 
        address underlying_, 
        address owner_,
        AmountsIn memory amounts_
    ) external {
        uint amountIn = amounts_.amountIn;
        underlying_.safeTransferFrom(owner_, address(this), amountIn);

        //Swaps underlying to WETH in Uniswap
        uint amountOut = _swapUni(
            amountIn, amounts_.minWethOut, underlying_, s.WETH, address(this)
        );

        if (_checkRocketCapacity(amountOut)) {
            IWETH(s.WETH).withdraw(amountOut);
            address rocketDepositPool = IRocketStorage(s.rocketPoolStorage).getAddress(s.rocketDepositPoolID); //Try here to store the depositPool with SSTORE2-3 (if it's cheaper in terms of gas) ***
            
            IRocketDepositPool(rocketDepositPool).deposit{value: amountOut}();
        } else {
            (bool paused,,) = IPool(s.rEthWethPoolBalancer).getPausedState();
            if (paused) {
                //do something else or throw error and return
            }

            _swapBalancer( //check if both balancer and uni swaps can be done with multicall
                s.WETH,
                s.rETH,
                IWETH(s.WETH).balanceOf(address(this)),
                amounts_.minRethOut
            );
        }
    }


    function _checkRocketCapacity(uint amountIn_) private view returns(bool) {
        uint poolBalance = IRocketVault(s.rocketVault).balanceOf('rocketDepositPool');
        uint capacityNeeded = poolBalance + amountIn_;

        IRocketDAOProtocolSettingsDeposit settingsDeposit = IRocketDAOProtocolSettingsDeposit(IRocketStorage(s.rocketPoolStorage).getAddress(s.rocketDAOProtocolSettingsDepositID));
        uint maxDepositSize = settingsDeposit.getMaximumDepositPoolSize();

        return capacityNeeded < maxDepositSize;
    }


    function useOzTokens(
        address owner_,
        bytes memory data_
    ) external returns(uint amountOut) {
        (
            uint ozAmountIn,
            uint amountInReth,
            uint minAmountOutWeth,
            uint minAmountOutUnderlying, 
            address receiver
        ) = abi.decode(data_, (uint, uint, uint, uint, address));

        console.log('amountInReth in useOz:**** ', amountInReth);

        msg.sender.safeTransferFrom(owner_, address(this), ozAmountIn);

        //Swap rETH to WETH
        _swapBalancer(
            s.rETH,
            s.WETH,
            amountInReth,
            minAmountOutWeth
        );

        console.log('weth bal useOz: ', IERC20Permit(s.WETH).balanceOf(address(this)));

        IUniswapV3Pool pool = IUniswapV3Pool();


        //swap WETH to underlying
        amountOut = _swapUni(
            IERC20Permit(s.WETH).balanceOf(address(this)),
            minAmountOutUnderlying,
            s.WETH,
            ozIToken(msg.sender).asset(),
            receiver
        );

        console.log('amountOut in useOz: ', amountOut);
    }


    function totalUnderlying(Asset type_) public view returns(uint total) {
        total = IERC20Permit(s.rETH).balanceOf(address(this));

        if (type_ == Asset.USD) {
            (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
            total = uint(price).mulDivDown(total, 1e8);
        }
    }

    
    


    //**** HELPERS */
    function _swapUni(
        uint amountIn_, 
        uint minAmountOut_, 
        address tokenIn_,
        address tokenOut_,
        address receiver_
    ) private returns(uint) {
        tokenIn_.safeApprove(s.swapRouterUni, amountIn_);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({ 
                tokenIn: tokenIn_,
                tokenOut: tokenOut_, 
                fee: 500, //0.05 - 500 / make this a programatic value
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: _formatMinOut(minAmountOut_, tokenOut_),
                sqrtPriceLimitX96: 0
            });

        try ISwapRouter(s.swapRouterUni).exactInputSingle(params) returns(uint amountOut) { 
            return amountOut;
        } catch Error(string memory reason) {
            revert OZError01(reason);
        }
    }

    //This func is in Helpers.sol also ****
    function _formatMinOut(uint minOut_, address tokenOut_) private view returns(uint) {
        uint decimals = IERC20Permit(tokenOut_).decimals();
        return decimals == 18 ? minOut_ : minOut_ / 10 ** (18 - decimals);
    }


    function _swapBalancer(
        address assetIn_, 
        address assetOut_, 
        uint amountIn_,
        uint minAmountOutOffchain_
    ) private {
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: IPool(s.rEthWethPoolBalancer).getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(assetIn_),
            assetOut: IAsset(assetOut_),
            amount: amountIn_,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false, //check if i can do something with internalBalance instead of external swap
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        uint minOutOnchain = IQueries(s.queriesBalancer).querySwap(singleSwap, funds); //remove this querySwap to save gas
        uint minOut = minAmountOutOffchain_ > minOutOnchain ? minAmountOutOffchain_ : minOutOnchain;

        assetIn_.safeApprove(s.vaultBalancer, singleSwap.amount);
        uint amountOut = IVault(s.vaultBalancer).swap(singleSwap, funds, minOut, block.timestamp);
        if (amountOut == 0) revert InvalidBalancerSwap();
    }


   



    /**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */
    // function _calculateMinOut(uint erc20Balance_) private view returns(uint minOut) {
    //     (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
    //     uint expectedOut = erc20Balance_.fullmulDivDown(uint(price) * 10 ** 10, 1 ether);
    //     uint minOutUnprocessed = 
    //         expectedOut - expectedOut.fullmulDivDown(s.defaultSlippage * 100, 1000000); 
    //     minOut = minOutUnprocessed.mulWad(10 ** 6);
    // }

    // function changeETHUSDfeed() external {}

}