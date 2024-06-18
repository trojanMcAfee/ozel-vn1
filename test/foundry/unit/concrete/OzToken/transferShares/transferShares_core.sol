// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";
import "./../../../../../../contracts/Errors.sol";


contract TransferShares_Core is SharedConditions {

    event TransferShares(address indexed from, address indexed to, uint sharesAmount);
    event Transfer(address indexed from, address indexed to, uint256 value);


    function it_should_transfer_shares_and_emit_events(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(),
            alice,
            address(ozERC20)
        );

        vm.startPrank(alice);
        IERC20(underlying).approve(address(OZ), amountIn);
        uint sharesOut = ozERC20.mint(data, alice);

        assertEq(sharesOut, ozERC20.sharesOf(alice));

        uint ozBalanceAlicePreTransfer = ozERC20.balanceOf(alice);
        uint ozBalanceBobPreTransfer = ozERC20.balanceOf(bob);
        assertEq(ozBalanceBobPreTransfer, 0);

        //Action
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, ozBalanceAlicePreTransfer);

        vm.expectEmit(true, true, false, true);
        emit TransferShares(alice, bob, sharesOut);

        uint ozBalanceOut = ozERC20.transferShares(bob, sharesOut);
        

        //Post-conditions
        uint ozBalanceBobPostTransfer = ozERC20.balanceOf(bob);
        uint ozBalanceAlicePostTransfer = ozERC20.balanceOf(alice);

        assertEq(ozBalanceAlicePreTransfer, ozBalanceOut);
        assertEq(ozBalanceAlicePreTransfer, ozBalanceBobPostTransfer);
        assertEq(ozBalanceAlicePostTransfer, 0);
    }


    function it_should_throw_error_07(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        uint sharesAlice = _mintOzTokens(ozERC20, alice, underlying, amountIn);
        uint sharesToTransfer = sharesAlice * 2;

        //Actions + Post-condition
        vm.startPrank(alice);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                OZError07.selector, 
                alice, 
                ozERC20.sharesOf(alice), 
                sharesToTransfer
            )
        );
        ozERC20.transferShares(bob, sharesToTransfer);
    }


    function it_should_throw_error_04(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        uint sharesAlice = _mintOzTokens(ozERC20, alice, underlying, amountIn);

        //Actions + Post-condition
        vm.startPrank(alice);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                OZError04.selector, alice, address(0)
            )
        );
        ozERC20.transferShares(address(0), sharesAlice);
    }


    function it_should_throw_error_42(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        uint sharesAlice = _mintOzTokens(ozERC20, alice, underlying, amountIn);

        //Actions + Post-condition
        vm.startPrank(alice);
        
        vm.expectRevert(
            abi.encodeWithSelector(OZError42.selector)
        );
        ozERC20.transferShares(address(ozERC20), sharesAlice);
    }
}