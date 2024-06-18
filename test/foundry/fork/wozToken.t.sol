// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../base/TestMethods.sol";
import {wozIToken} from "../../../contracts/interfaces/wozIToken.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {HelpersLib} from "../utils/HelpersLib.sol";

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

        _mock_rETH_ETH_pt1();

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

        /**
         * The difference remaining in ozTokens is less than 1.1e-12, which
         * corresponds to the dust from being a rebase token. 
         */
        assertTrue(ozBalanceAlice < 11 * 1e13);

        //Accrue rewards
        // _accrueRewards(100);
        vm.warp(block.timestamp + 100);
        _mock_rETH_ETH_pt2();

        uint ozBalanceBobPostAccrual = ozERC20.balanceOf(bob);
        assertTrue(ozBalanceBobPostAccrual > ozBalanceBob);

        uint wozBalanceAlicePostAccrual = wozERC20.balanceOf(alice);
        assertTrue(wozBalanceAlicePostAccrual == wozBalanceAlice);

        uint ozBalanceAlicePostAccrual = ozERC20.balanceOf(alice); 
        assertTrue(ozBalanceAlicePostAccrual < 11 * 1e13);

        uint ozBalanceWozPostAccrual = ozERC20.balanceOf(address(wozERC20));
        assertTrue(_fm(ozBalanceWozPostAccrual, 13) == _fm(ozBalanceBobPostAccrual, 13));

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
    function test_mint_and_wrap() public {
        //Pre-conditions
        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        bytes memory data = OZ.getMintData(
            amountIn, 
            OZ.getDefaultSlippage(), 
            alice,
            address(ozERC20)
        );

        //Action
        uint wozAmountOut = wozERC20.mintAndWrap(data, alice);

        assertTrue(wozAmountOut == wozERC20.balanceOf(alice));
        vm.stopPrank();

        assertTrue(ozERC20.balanceOf(alice) == 0);
    }


    function test_transfer_permit() public {
        //Pre-conditions
        (, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        bytes memory data = OZ.getMintData(
            amountIn, 
            OZ.getDefaultSlippage(), 
            alice,
            address(wozERC20)
        );

        wozERC20.mintAndWrap(data, alice);
        vm.stopPrank();

        uint wozAmountInAlice = wozERC20.balanceOf(alice);
        assertTrue(wozAmountInAlice > 0);

        bytes32 permitHash = HelpersLib.getPermitHash(
            address(wozERC20),
            alice,
            bob,
            wozAmountInAlice,
            wozERC20.nonces(alice),
            block.timestamp
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, permitHash);

        //Actions
        vm.prank(alice);
        wozERC20.permit(
            alice,
            bob,
            wozAmountInAlice,
            block.timestamp,
            v, r, s
        );

        uint wozBalanceCharliePreTransfer = wozERC20.balanceOf(charlie);
        assertTrue(wozBalanceCharliePreTransfer == 0);

        vm.prank(bob);
        wozERC20.transferFrom(alice, charlie, wozAmountInAlice);

        //Post-conditions
        uint wozBalanceAlicePostTransfer = wozERC20.balanceOf(alice);
        assertTrue(wozBalanceAlicePostTransfer == 0);

        uint wozBalanceCharliePostTransfer = wozERC20.balanceOf(charlie);
        assertTrue(wozBalanceCharliePostTransfer == wozAmountInAlice);
    }


}