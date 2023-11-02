// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import "../../lib/forge-std/src/interfaces/IERC20.sol"; 
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {
    AppStorage, 
    TradeAmounts, 
    TradeAmountsOut, 
    Asset
} from "../AppStorage.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {IWETH} from "../interfaces/IWETH.sol";
// import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {IVault, IAsset, IPool} from "../interfaces/IBalancer.sol";
import {IPool, IQueries} from "../interfaces/IBalancer.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";

import "forge-std/console.sol";


error TokenInNotValid(address token);


contract ROImoduleL2 {

    using TransferHelper for address;
    using FixedPointMathLib for uint;
  
    AppStorage internal s;


    function useUnderlying( 
        address underlying_, 
        address user_,
        TradeAmounts memory amounts_
    ) external {
        bytes32 poolId = IPool(s.rEthWethPoolBalancer).getPoolId();
        underlying_.safeTransferFrom(user_, address(this), amounts_.amountIn);

        //Swaps underlying to WETH in Uniswap
        _swapUni(amounts_.amountIn, amounts_.minWethOut, underlying_);

        //Swaps WETH to rETH in Balancer
        (bool paused,,) = IPool(s.rEthWethPoolBalancer).getPausedState();
        if (paused) {
            //do something else or throw error and return
        }

        _swapBalancer(poolId, amounts_.minRethOut);

        //Deposits rETH in rETH-ETH Balancer pool as LP
        _addLiquidityBalancer(amounts_.minBptOut, poolId);

        //******** */
        // _removeLiquidityBalancer(uint(0), bptBalance, poolId, user_); //offchain calc goes in uint(0)

    }


    function useOzTokens(
        TradeAmountsOut memory amts_,
        address ozToken_,
        address owner_,
        address receiver_
    ) external {
        bytes32 poolId = IPool(s.rEthWethPoolBalancer).getPoolId();
        ozToken_.safeTransferFrom(owner_, address(this), amts_.ozAmountIn);

        _removeLiquidityBalancer(
            amts_.minWethOut, amts_.bptAmountIn, poolId
        ); 

        uint bal = IERC20Permit(s.USDC).balanceOf(receiver_);
        console.log('usdc bal pre: ', bal);

        _swapUni(
            IERC20Permit(s.WETH).balanceOf(address(this)),
            amts_.minUsdcOut,
            s.WETH,
            s.USDC,
            receiver_
        );

        bal = IERC20Permit(s.USDC).balanceOf(receiver_);
        console.log('usdc bal post: ', bal);

        revert('exittooo2');

        //Swap WETH to USDC
        // _swapUni();

        
    }


    function totalUnderlying(Asset type_) public view returns(uint total) {
        total = IERC20Permit(s.rEthWethPoolBalancer).balanceOf(address(this));

        if (type_ == Asset.USD) {
            (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
            total = uint(price).mulDiv(total, 1e8);
        }
    }


    function _removeLiquidityBalancer(
        uint minWethOut_, 
        uint bptAmountIn_, 
        bytes32 poolId_
    ) private {
        address[] memory assets = Helpers.convertToDynamic([s.WETH, s.rEthWethPoolBalancer, s.rETH]);
        uint[] memory minAmountsOut = Helpers.convertToDynamic([minWethOut_, uint(0), uint(0)]);

        bytes memory userData = Helpers.createUserData(
            IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn_, 0 //exitTokenIndex
        );

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        IVault(s.vaultBalancer).exitPool( 
            poolId_, 
            address(this), 
            payable(address(this)), 
            request
        );

    }




    //**** HELPERS */
    function _swapUni(
        uint amountIn_, 
        uint minWethOut_, 
        address underlying_
    ) private {
        underlying_.safeApprove(s.swapRouterUni, amountIn_);

        //implement multihop swap for tokens with no single swap in Uniswap

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: underlying_,
                tokenOut: s.WETH, 
                fee: 500, //0.05 - 500 / make this a programatic value
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minWethOut_, //minWethOut_
                sqrtPriceLimitX96: 0
            });

        uint amountOut = ISwapRouter(s.swapRouterUni).exactInputSingle(params); 
        if (amountOut == 0) revert TokenInNotValid(underlying_);
    }

    function _formatMinOut(uint minOut_, address tokenOut_) private view returns(uint) {
        uint decimals = IERC20Permit(tokenOut_).decimals();
        return decimals == 18 ? minOut_ : minOut_ / 10 ** (18 - decimals);
    }

    function _swapUni(
        uint amountIn_, 
        uint minAmountOut_, 
        address tokenIn_,
        address tokenOut_,
        address receiver_
    ) private {
        tokenIn_.safeApprove(s.swapRouterUni, amountIn_);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({ 
                tokenIn: tokenIn_,
                tokenOut: tokenOut_, 
                fee: 500, //0.05 - 500 / make this a programatic value
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: _formatMinOut(minAmountOut_, tokenOut_), //minWethOut_
                sqrtPriceLimitX96: 0
            });

        uint amountOut = ISwapRouter(s.swapRouterUni).exactInputSingle(params); 
        if (amountOut == 0) revert TokenInNotValid(tokenIn_);
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

        address[] memory assets = Helpers.convertToDynamic([s.WETH, s.rEthWethPoolBalancer, s.rETH]);
        uint[] memory maxAmountsIn = Helpers.convertToDynamic([0, 0, amountIn]);
        uint[] memory amountsIn = Helpers.convertToDynamic([0, amountIn]);

        IVault.JoinPoolRequest memory request = Helpers.createRequest(
            assets, maxAmountsIn, Helpers.createUserData(
                IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBptOutOffchain_
            )
        );

        (uint bptOut,) = IQueries(s.queriesBalancer).queryJoin(
            poolId_,
            address(this),
            address(this),
            request
        );

        //Re-do request with actual bptOut
        uint minBptOut = Helpers.calculateMinAmountOut(
            bptOut > minBptOutOffchain_ ? bptOut : minBptOutOffchain_, 
            s.defaultSlippage
        );

        request = Helpers.createRequest(
            assets, maxAmountsIn, Helpers.createUserData(
                IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBptOut
            )
        );

        IVault(s.vaultBalancer).joinPool(
            poolId_,
            address(this),
            address(this),
            request
        );
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