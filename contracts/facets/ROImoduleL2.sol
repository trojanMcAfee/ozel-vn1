// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import "../../lib/forge-std/src/interfaces/IERC20.sol"; 
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage} from "../AppStorage.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IRocketStorage} from "../interfaces/IRocketStorage.sol";
// import {IVault, IAsset, IPool} from "../interfaces/IBalancer.sol";
import {IPool, IQueries} from "../interfaces/IBalancer.sol";
import "../libraries/Helpers.sol";


import "forge-std/console.sol";




contract ROImoduleL2 {

    using TransferHelper for address;
    using Helpers for bytes32;
    using Helpers for address;
    // using Helpers for uint[];

    AppStorage internal s;

    function useUnderlying( 
        address underlying_, 
        address user_,
        uint minWethOut_,
        uint minRethOutOffchain_
    ) external {
        //Swaps underlying to WETH in Uniswap
        uint amountIn = IERC20(underlying_).balanceOf(address(this));
        underlying_.safeApprove(s.swapRouterUni, amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: underlying_,
                tokenOut: s.WETH, 
                fee: 500, //make this a programatic value
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minWethOut_, 
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(s.swapRouterUni).exactInputSingle(params);

        //Swaps WETH to rETH in Balancer
        (bool paused,,) = IPool(s.rEthWethPoolBalancer).getPausedState();
        if (paused) {
            //do something else or throw error and return
        }

        IVault.SingleSwap memory singleSwap = IPool(s.rEthWethPoolBalancer)
            .getPoolId()
            .createSingleSwap(
                IVault.SwapKind.GIVEN_IN,
                IAsset(s.WETH),
                IAsset(s.rETH),
                IWETH(s.WETH).balanceOf(address(this))
            );

        IVault.FundManagement memory fundMngmt = address(this).createFundMngmt(payable(address(this)));
        uint minRethOutOnchain = IQueries(s.queriesBalancer).querySwap(singleSwap, fundMngmt);

        uint minRethOut = minRethOutOffchain_ > minRethOutOnchain ? minRethOutOffchain_ : minRethOutOnchain;

        s.WETH.safeApprove(s.vaultBalancer, singleSwap.amount);
        IVault(s.vaultBalancer).swap(singleSwap, fundMngmt, minRethOut, block.timestamp);

        //Deposits rETH in rETH-ETH Balancer pool as LP
        s.rETH.safeApprove(s.vaultBalancer, IWETH(s.rETH).balanceOf(address(this)));

        address[] memory assets = new address[](3);
        assets[0] = s.WETH;
        assets[1] = s.rEthWethPoolBalancer;
        assets[2] = s.rETH;

        uint[] memory maxAmountsIn = new uint[](3);
        maxAmountsIn[0] = 0;
        maxAmountsIn[1] = 0;
        maxAmountsIn[2] = IWETH(s.rETH).balanceOf(address(this));

        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 0;
        amountsIn[1] = IWETH(s.rETH).balanceOf(address(this));

        uint minAmountBptOut = 0; //0

        
        bytes memory userData = abi.encode( 
            IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            minAmountBptOut
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        // (uint bptOut,) = IQueries(s.queriesBalancer).queryJoin(
        //     IPool(s.rEthWethPoolBalancer).getPoolId(),
        //     address(this),
        //     address(this)
        // );

       

        IVault(s.vaultBalancer).joinPool(
            IPool(s.rEthWethPoolBalancer).getPoolId(),
            address(this),
            address(this),
            request
        );

        uint bal = IWETH(s.rEthWethPoolBalancer).balanceOf(address(this));
        // console.log('bal BPT post: ', bal);

    }


    //**** HELPERS */

    // function _calculateUserData(uint minBptOut_) private returns(bytes memory) {
    //     return abi.encode( 
    //         IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
    //         amountsIn,
    //         minBptOut_
    //     );
    // }

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