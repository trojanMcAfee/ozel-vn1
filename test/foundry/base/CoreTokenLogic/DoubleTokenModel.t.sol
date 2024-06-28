// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;



import {IERC20Permit} from "./../../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "./../../../../contracts/interfaces/ozIToken.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AmountsIn} from "./../../../../contracts/AppStorage.sol";
import {HelpersLogic} from "./helpers/HelpersLogic.sol";


import "forge-std/console.sol";



contract DoubleTokenModelTest is HelpersLogic {


    function test_strategy_new() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();   
        console.log('amountInStable in test: ', amountIn);

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        bytes memory mintData = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice, address(ozERC20));
        (AmountsIn memory amts,) = abi.decode(mintData, (AmountsIn, address));
        // console.log('amts.amountInETH alice ^^^^^^: ', amts.amountInETH);

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
        console.log('block.timestamp  in test: ', block.timestamp);
        console.log('halfAccrual - 3 days: ', halfAccrual);
        vm.warp(halfAccrual);

        //---- mock BALANCER WETH > rETH swap ----
        //Has to be a mock because balancer fails when swapping after warp
        //total rETH that'll be swapped, representing the staking rewards earned
        uint amountToSwapRETH = _balancerPart(halfAccrual, false);
        _bobDeposit(ozERC20, amountIn);
        //---------------------

        uint blockAccrual = halfAccrual + 4 days;
        console.log('blockAccrual - 7 days: ', blockAccrual);
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

        console.log('');
        console.log('--------------------');
        console.log('start of executeRebaseSwap');
        console.log('--------------------');
        console.log('');

        assertTrue(OZ.executeRebaseSwap());

        deal(rEthAddr, address(OZ), IERC20(rEthAddr).balanceOf(address(OZ)) - amountToSwapRETH); //add both deposits here
        
        uint newBalanceRETH = IERC20Permit(rEthAddr).balanceOf(address(OZ));
        assertTrue(oldBalanceRETH > newBalanceRETH);

        console.log('sysBalanceRETH - post swap: ', newBalanceRETH);
        //**************** */

        console.log('');
        console.log('bal alice oz: ', ozERC20.balanceOf(alice));
        console.log('bal bob oz: ', ozERC20.balanceOf(bob));

    }






}