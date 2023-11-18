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
import "solady/src/utils/FixedPointMathLib.sol";
import {IWETH} from "../interfaces/IWETH.sol";
// import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {IVault, IAsset, IPool} from "../interfaces/IBalancer.sol";
import {IPool, IQueries} from "../interfaces/IBalancer.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {ozIToken} from "../interfaces/ozIToken.sol";

import "forge-std/console.sol";


error TokenInNotValid(address token);


contract ROImoduleL2 {

    using TransferHelper for address;
    using FixedPointMathLib for uint;
  
    AppStorage internal s;


    function useUnderlying( 
        address underlying_, 
        address user_,
        AmountsIn memory amounts_
    ) external {
        bytes32 poolId = IPool(s.rEthWethPoolBalancer).getPoolId();
        underlying_.safeTransferFrom(user_, address(this), amounts_.amountIn);

        //Swaps underlying to WETH in Uniswap
        _swapUni(
            amounts_.amountIn, amounts_.minWethOut, underlying_, s.WETH, address(this)
        );

        //Swaps WETH to rETH in Balancer
        (bool paused,,) = IPool(s.rEthWethPoolBalancer).getPausedState();
        if (paused) {
            //do something else or throw error and return
        }

        // _swapBalancer(poolId, amounts_.minRethOut);

        //Deposits WETH in rETH-ETH Balancer pool as LP
        //Skips the rETH swap since it receives the same amt of BPT in the end
        _addLiquidityBalancer(amounts_.minBptOut, poolId);
    }


    function useOzTokens(
        AmountsOut memory amts_,
        address ozToken_,
        address owner_,
        address receiver_
    ) external returns(uint amountOut) {
        bytes32 poolId = IPool(s.rEthWethPoolBalancer).getPoolId();

        ozToken_.safeTransferFrom(owner_, address(this), amts_.ozAmountIn);

        _removeLiquidityBalancer(
            amts_.minWethOut, amts_.bptAmountIn, poolId
        ); 

        amountOut =_swapUni(
            IERC20Permit(s.WETH).balanceOf(address(this)),
            amts_.minUsdcOut,
            s.WETH,
            s.USDC,
            receiver_
        );
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
        uint minAmountOut_, 
        address tokenIn_,
        address tokenOut_,
        address receiver_
    ) private returns(uint amountOut) {
        console.log('--- swap uni ---');
        console.log('amountIn: ', amountIn_);
        // console.log('amountOutMinimum: ', _formatMinOut(minAmountOut_, tokenOut_));

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

        amountOut = ISwapRouter(s.swapRouterUni).exactInputSingle(params); 
        console.log('amountOut weth uni ^^: ', amountOut);
        console.log('--- end of swap uni ---');
        if (amountOut == 0) revert TokenInNotValid(tokenIn_);
    }

    //This func is in Helpers.sol also ****
    function _formatMinOut(uint minOut_, address tokenOut_) private view returns(uint) {
        uint decimals = IERC20Permit(tokenOut_).decimals();
        return decimals == 18 ? minOut_ : minOut_ / 10 ** (18 - decimals);
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
        uint amountOut = IVault(s.vaultBalancer).swap(singleSwap, funds, minRethOut, block.timestamp);
        console.log('amountOut reth balancer !!: ', amountOut);
    }


    function _addLiquidityBalancer(uint minBptOutOffchain_, bytes32 poolId_) private {
        uint amountIn = IERC20Permit(s.WETH).balanceOf(address(this));
        s.WETH.safeApprove(s.vaultBalancer, amountIn);

        address[] memory assets = Helpers.convertToDynamic([s.WETH, s.rEthWethPoolBalancer, s.rETH]);
        uint[] memory maxAmountsIn = Helpers.convertToDynamic([amountIn, 0, 0]);
        uint[] memory amountsIn = Helpers.convertToDynamic([amountIn, 0]);

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
        console.log('bpt bal post join ##: ', IWETH(s.rEthWethPoolBalancer).balanceOf(address(this)));
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