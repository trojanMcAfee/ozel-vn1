// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {wozIToken} from "../../contracts/interfaces/wozIToken.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {NewToken} from "../../contracts/AppStorage.sol";
import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC4626Upgradeable.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol";


contract wozTokenTest is TestMethods {

    //One user deposits ozERC20 to mint wozERC20, and then withdraws them back for ozERC20
    function test_wrap_unwrap_oneUser() public { 
        //Pre-conditions
        (bytes32 oldSlot0data, bytes32 oldSharedCash, bytes32 cashSlot) = _getResetVarsAndChangeSlip();

        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        _mintOzTokens(ozERC20, alice, testToken, amountIn); 
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        uint ozBalancePre = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePre > 0);

        uint wozBalancePre = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePre == 0);

        address underlying = wozERC20.asset();
        assertTrue(underlying == address(ozERC20));

        //Actions
        vm.startPrank(alice);

        ozERC20.approve(address(wozERC20), ozBalancePre);
        uint wozAmountOut = wozERC20.wrap(ozBalancePre, alice, alice);

        uint wozBalancePost = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePost > 0);
        assertTrue(wozAmountOut == wozBalancePost);

        uint ozBalancePost = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePost == 0);

        uint ozAmountOut = wozERC20.unwrap(wozBalancePost, alice, alice);
        uint wozBalancePostWithdrawal = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePostWithdrawal == 0);

        //Post-condition
        uint ozBalancePostWithdrawal = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePostWithdrawal > 0);
        assertTrue(ozAmountOut == ozBalancePostWithdrawal);

        vm.stopPrank();
    }


    //Tests that wozERC20 stays the same value while ozERC20 accrues rewards, and
    //end user claims all of them at the end of the tx flow
    function test_wozToken_stability() public {
        (bytes32 oldSlot0data, bytes32 oldSharedCash, bytes32 cashSlot) = _getResetVarsAndChangeSlip();

        //create ozToken
        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);
        uint amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();

        //mint ozTokens
        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        _mintOzTokens(ozERC20, bob, testToken, amountIn); 

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        uint ozBalanceBob = ozERC20.balanceOf(bob);
        assertTrue(ozBalanceAlice == ozBalanceBob);
        
        //Mint wozERC20 from ozERC20
        vm.startPrank(alice);
        ozERC20.approve(address(wozERC20), ozBalanceAlice);
        wozERC20.wrap(ozBalanceAlice, alice, alice); 
        vm.stopPrank();

        uint wozBalanceAlice = wozERC20.balanceOf(alice);

        ozBalanceAlice = ozERC20.balanceOf(alice); 
        assertTrue(ozBalanceAlice == 0);

        //Accrue rewards
        _accrueRewards(100);

        uint ozBalanceBobPostAccrual = ozERC20.balanceOf(bob);
        assertTrue(ozBalanceBobPostAccrual > ozBalanceBob);

        uint wozBalanceAlicePostAccrual = wozERC20.balanceOf(alice);
        assertTrue(wozBalanceAlicePostAccrual == wozBalanceAlice);

        uint ozBalanceAlicePostAccrual = ozERC20.balanceOf(alice); 
        assertTrue(ozBalanceAlicePostAccrual == 0);

        uint ozBalanceWozPostAccrual = ozERC20.balanceOf(address(wozERC20));
        assertTrue(ozBalanceWozPostAccrual == ozBalanceBobPostAccrual);

        //Redeem wozERC20 for ozERC20
        vm.prank(alice);
        wozERC20.unwrap(wozBalanceAlice, alice, alice); 

        uint wozBalanceAlicePostUnwrap = wozERC20.balanceOf(alice);
        assertTrue(wozBalanceAlicePostUnwrap == 0);
        
        uint ozBalanceAlicePostUnwrap = ozERC20.balanceOf(alice);
        assertTrue(ozBalanceAlicePostUnwrap == ozBalanceBobPostAccrual);

        uint ozBalanceBobPostUnwrap = ozERC20.balanceOf(bob);
        assertTrue(ozBalanceBobPostUnwrap == ozBalanceBobPostAccrual);

        uint ozBalanceWozPostUnwrap = ozERC20.balanceOf(address(wozERC20));
        assertTrue(ozBalanceWozPostUnwrap == 0);
    }

    //tests the mintAndWrap() function    
    function test_mint_and_wrap() public returns(wozIToken) {
        //Pre-conditions
        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        bytes memory data = OZ.getMintData(
            amountIn, 
            testToken, 
            OZ.getDefaultSlippage(), 
            alice
        );

        //Action
        uint wozAmountOut = wozERC20.mintAndWrap(data, alice);
        assertTrue(wozAmountOut == wozERC20.balanceOf(alice));
        vm.stopPrank();

        assertTrue(ozERC20.balanceOf(alice) == 0);

        return wozERC20;
    }


}