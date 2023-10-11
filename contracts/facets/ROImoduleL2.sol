// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import "../../lib/forge-std/src/interfaces/IERC20.sol"; 
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage, TradeAmounts} from "../AppStorage.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IRocketStorage} from "../interfaces/IRocketStorage.sol";
// import {IVault, IAsset, IPool} from "../interfaces/IBalancer.sol";
import {IPool, IQueries} from "../interfaces/IBalancer.sol";
import "../libraries/Helpers.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import "../../contracts/interfaces/IERC20Permit.sol";

import "forge-std/console.sol";



contract ROImoduleL2 {

    using TransferHelper for address;
    using Helpers for bytes32;
    using Helpers for address;
    using FixedPointMathLib for uint;

    AppStorage internal s;

    function useUnderlying( 
        address underlying_, 
        address user_,
        TradeAmounts memory amounts_
    ) external {
        uint amountIn = amounts_.amountIn;
        uint minWethOut = amounts_.minWethOut;
        uint minRethOutOffchain = amounts_.minRethOut;
        uint minBptOutOffchain = amounts_.minBptOut;

        IERC20Permit(underlying_).transferFrom(user_, address(this), amountIn);

        //Swaps underlying to WETH in Uniswap
        _swapUni(amountIn, minWethOut, underlying_);

        //Swaps WETH to rETH in Balancer
        (bool paused,,) = IPool(s.rEthWethPoolBalancer).getPausedState();
        if (paused) {
            //do something else or throw error and return
        }

        bytes32 poolId = IPool(s.rEthWethPoolBalancer).getPoolId();

        _swapBalancer(poolId, minRethOutOffchain);

        //Deposits rETH in rETH-ETH Balancer pool as LP
        _addLiquidityBalancer(minBptOutOffchain, poolId);

        uint bal = IWETH(s.rEthWethPoolBalancer).balanceOf(address(this));
        console.log('bal BPT post: ', bal);

    }


    //**** HELPERS */

    function _calculateMinAmountOut(
        uint256 amount_
    ) private view returns(uint256 minAmountOut) {
        minAmountOut = amount_ - amount_.fullMulDiv(s.defaultSlippage, 10000);
    }


    function _swapUni(
        uint amountIn_, 
        uint minWethOut_, 
        address underlying_
    ) private {
        underlying_.safeApprove(s.swapRouterUni, amountIn_);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: underlying_,
                tokenOut: s.WETH, 
                fee: 500, //make this a programatic value
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minWethOut_, 
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(s.swapRouterUni).exactInputSingle(params);
    }


    function _swapBalancer(bytes32 poolId_, uint minRethOutOffchain_) private {
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: poolId_,
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(s.WETH),
            assetOut: IAsset(s.rETH),
            amount: IWETH(s.WETH).balanceOf(address(this)),
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        uint minRethOutOnchain = IQueries(s.queriesBalancer).querySwap(singleSwap, funds);
        uint minRethOut = minRethOutOffchain_ > minRethOutOnchain ? minRethOutOffchain_ : minRethOutOnchain;

        s.WETH.safeApprove(s.vaultBalancer, singleSwap.amount);
        IVault(s.vaultBalancer).swap(singleSwap, funds, minRethOut, block.timestamp);
    }


    function _addLiquidityBalancer(uint minBptOutOffchain_, bytes32 poolId_) private {
        uint amountIn = IERC20Permit(s.rETH).balanceOf(address(this));
        s.rETH.safeApprove(s.vaultBalancer, amountIn);

        address[] memory assets = new address[](3);
        assets[0] = s.WETH;
        assets[1] = s.rEthWethPoolBalancer;
        assets[2] = s.rETH;

        uint[] memory maxAmountsIn = new uint[](3);
        maxAmountsIn[0] = 0;
        maxAmountsIn[1] = 0;
        maxAmountsIn[2] = amountIn;

        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 0;
        amountsIn[1] = amountIn;

        IVault.JoinPoolRequest memory request = _createRequest(
            assets, maxAmountsIn, _createUserData(amountsIn, minBptOutOffchain_)
        );

        (uint bptOut,) = IQueries(s.queriesBalancer).queryJoin(
            poolId_,
            address(this),
            address(this),
            request
        );

        //Re-do request with actual bptOut
        uint minBptOut = _calculateMinAmountOut(
            bptOut > minBptOutOffchain_ ? bptOut : minBptOutOffchain_
        );

        request = _createRequest(
            assets, maxAmountsIn, _createUserData(amountsIn, minBptOut)
        );

        IVault(s.vaultBalancer).joinPool(
            poolId_,
            address(this),
            address(this),
            request
        );
    }

    // function _createArray(uint length_, )

    function _createUserData(
        uint[] memory amountsIn_, 
        uint minBptOut_
    ) private pure returns(bytes memory) {
        return abi.encode( 
            IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn_,
            minBptOut_
        );
    }

    function _createRequest(
        address[] memory assets_,
        uint[] memory maxAmountsIn_,
        bytes memory userData_
    ) private pure returns(IVault.JoinPoolRequest memory) {
        return IVault.JoinPoolRequest({
            assets: assets_,
            maxAmountsIn: maxAmountsIn_,
            userData: userData_,
            fromInternalBalance: false
        });
    }



    /**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */
    // function _calculateMinOut(uint erc20Balance_) private view returns(uint minOut) {
    //     (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
    //     uint expectedOut = erc20Balance_.fullMulDiv(uint(price) * 10 ** 10, 1 ether);
    //     uint minOutUnprocessed = 
    //         expectedOut - expectedOut.fullMulDiv(s.defaultSlippage * 100, 1000000); 
    //     minOut = minOutUnprocessed.mulWad(10 ** 6);
    // }

    // function changeETHUSDfeed() external {}

}