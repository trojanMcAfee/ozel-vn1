// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../TestMethods.sol";
import {FixedPointMathLib} from "../../../../contracts/libraries/FixedPointMathLib.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// --------
import {IERC20Permit} from "./../../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "./../../../../contracts/interfaces/ozIToken.sol";
import {IVault, IPool, IAsset} from "./../../../../contracts/interfaces/IBalancer.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AmountsIn} from "./../../../../contracts/AppStorage.sol";


import "forge-std/console.sol";



contract DoubleTokenModelTest is TestMethods {

    using FixedPointMathLib for uint;


    function _constructUniSwap(uint amountIn_) private view returns(ISwapRouter.ExactInputSingleParams memory) {
        return ISwapRouter.ExactInputSingleParams({ 
                tokenIn: wethAddr,
                tokenOut: testToken, 
                fee: uniPoolFee, 
                recipient: address(OZ),
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
    }


    function _constructBalancerSwap(bool isRebase_) private view returns(
        IVault.SingleSwap memory, 
        IVault.FundManagement memory
    ) {
        IAsset tokenIn = IAsset(isRebase_ ? rEthAddr : wethAddr);
        IAsset tokenOut = IAsset(isRebase_ ? wethAddr : rEthAddr);
        uint amountIn = isRebase_ ? 946135001651163 : 28398352812392632;

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: IPool(rEthWethPoolBalancer).getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: tokenIn,
            assetOut: tokenOut,
            amount: amountIn,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(OZ),
            fromInternalBalance: false, 
            recipient: payable(address(OZ)),
            toInternalBalance: false
        });

        return (singleSwap, funds);
    }

    function _balancerPart(uint blockAccrual, bool isRebase_) private returns(uint) {
        (
            IVault.SingleSwap memory singleSwap, 
            IVault.FundManagement memory funds
        ) = _constructBalancerSwap(isRebase_);

        uint rateRETHETH = isRebase_ ? 1154401364401861932 : 1111038024285138135;
        uint amountToSwap = isRebase_ ? 946135001651163 : 28398352812392632;
        uint swappedAmount = isRebase_ ? 
            rateRETHETH.mulDivDown(amountToSwap, 1 ether) :
            amountToSwap.mulDivDown(1 ether, rateRETHETH);

        uint oldAmountWETH = IERC20(wethAddr).balanceOf(address(this));
        // address tokenToSend = isRebase_ ? wethAddr : rEthAddr;
        console.log('');
        
        vm.mockCall(
            vaultBalancer,
            abi.encodeWithSelector(IVault.swap.selector, singleSwap, funds, 0, blockAccrual),
            abi.encode(swappedAmount)
        );
        deal(isRebase_ ? wethAddr : rEthAddr, address(OZ), swappedAmount);
        // assertTrue(oldAmountWETH < IERC20(wethAddr).balanceOf(address(OZ)));

        return amountToSwap;
    }

      //---- mock UNISWAP WETH<>USDC swap (not need for now since ETHUSD hasn't chan ged)----
        // ISwapRouter.ExactInputSingleParams memory params = _constructUniSwap(swappedAmountWETH);

        // vm.mockCall(
        //     swapRouterUni,
        //     abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, params),
        //     abi.encode()
        // );


    function test_strategy_new() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();   
        console.log('amountInStable in test: ', amountIn);

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        bytes memory mintData = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice, address(ozERC20));
        (AmountsIn memory amts,) = abi.decode(mintData, (AmountsIn, address));
        console.log('amts.amountInETH alice ^^^^^^: ', amts.amountInETH);

        payable(alice).transfer(1000 ether);

        vm.startPrank(alice);

        //Alice mints ozERC20
        IERC20(testToken).approve(address(OZ), amountIn);
        ozERC20.mint2{value: amts.amountInETH}(mintData, alice, true);

        vm.stopPrank();

        uint oldRateRETH = OZ.rETH_ETH();
        console.log('rETH_ETH - pre epoch: ', oldRateRETH);
        console.log('aUSDC bal in test - diamond - pre warp: ', IERC20Permit(aUsdcAddr).balanceOf(address(OZ)));

        /*** simulates time for staking rewards accrual ***/
        uint halfAccrual = block.timestamp + 3 days;
        vm.warp(halfAccrual);

        //---- mock BALANCER WETH > rETH swap ----
        //Has to be a mock because balancer fails when swapping after warp
        uint amountToSwapRETH = _balancerPart(halfAccrual, false);
        _bobDeposit(ozERC20, amountIn);

        //^^^ continue here with the accounting for rebase swap
        //---------------------

        uint blockAccrual = halfAccrual + 4 days;
        console.log('blockAccrual: ', blockAccrual);
        vm.warp(blockAccrual);

        console.log('');
        console.log('*** MOCK ***');
        console.log('');

        _mock_rETH_ETH_diamond();

        assertTrue(oldRateRETH < OZ.rETH_ETH());
        
        //---- mock BALANCER rETH > WETH swap ----
        amountToSwapRETH = _balancerPart(blockAccrual, true);

        //--------------------------------------
        console.log('rETH_ETH - post epoch: ', OZ.rETH_ETH());
        uint oldBalanceRETH = IERC20(rEthAddr).balanceOf(address(OZ));

        assertTrue(OZ.executeRebaseSwap());

        deal(rEthAddr, address(OZ), IERC20(rEthAddr).balanceOf(address(OZ)) - amountToSwapRETH); //add both deposits here
        
        uint newBalanceRETH = IERC20Permit(rEthAddr).balanceOf(address(OZ));
        assertTrue(oldBalanceRETH > newBalanceRETH);

        console.log('sysBalanceRETH - post swap: ', newBalanceRETH);
        //**************** */

        console.log('bal alice oz: ', ozERC20.balanceOf(alice));

    }


    function _bobDeposit(ozIToken ozERC20, uint amountIn) private {
        bytes memory mintData = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), bob, address(ozERC20));
        (AmountsIn memory amts,) = abi.decode(mintData, (AmountsIn, address));
        console.log('amts.amountInETH bob ^^^^^^: ', amts.amountInETH);

        payable(bob).transfer(500 ether);

        vm.startPrank(bob);

        IERC20(testToken).approve(address(OZ), amountIn);
        ozERC20.mint2{value: amts.amountInETH}(mintData, bob, true);

        vm.stopPrank();
    }




}