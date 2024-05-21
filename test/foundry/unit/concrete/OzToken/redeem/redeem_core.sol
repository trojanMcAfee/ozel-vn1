// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";
import {OZError06, OZError38, OZError39} from "./../../../../../../contracts/Errors.sol";

import {console} from "forge-std/console.sol";


contract Redeem_Core is SharedConditions {

    function it_should_revert(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        uint ozAmountIn = ozERC20.balanceOf(alice);

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, 
            address(ozERC20), 
            OZ.getDefaultSlippage(), 
            alice, 
            alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);

        //Action + Post-Condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError38.selector)
        );
        ozERC20.redeem(data, address(0));
    }


    function it_should_throw_error_06(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        uint ozAmountIn = ozERC20.balanceOf(alice) * 2;

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, 
            address(ozERC20), 
            OZ.getDefaultSlippage(), 
            alice, 
            alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);

        uint sharesAlice = ozERC20.sharesOf(alice);
        uint alledgedShares = ozERC20.subConvertToShares(ozAmountIn, alice);

        //Action + Post-Condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError06.selector, alice, sharesAlice, alledgedShares)
        );
        ozERC20.redeem(data, alice);
    }


    function it_should_throw_error_38(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        uint ozAmountIn = ozERC20.balanceOf(alice);

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, 
            address(ozERC20), 
            OZ.getDefaultSlippage(), 
            address(0), 
            alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);

        //Action + Post-Condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError38.selector)
        );
        ozERC20.redeem(data, alice);
    }


    function it_should_throw_error_39(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        uint ozAmountIn = ozERC20.balanceOf(alice);

        bytes memory data = abi.encode(ozAmountIn, deadAddr);

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);

        //Action + Post-Condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError39.selector, data)
        );
        ozERC20.redeem(data, alice);
    }


    function it_should_redeem(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        uint ozAmountIn = ozERC20.balanceOf(alice);

        console.log('ozBalance alice - pre redeem: ', ozAmountIn);
        console.log('underlying bal alice - pre redeem: ', IERC20(underlying).balanceOf(alice));

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, 
            address(ozERC20), 
            OZ.getDefaultSlippage(), 
            alice, 
            alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);

        //Action + Post-Condition
        ozERC20.redeem(data, alice);

        console.log('ozBalance alice - post redeem: ', ozERC20.balanceOf(alice));
        console.log('underlying bal alice - post redeem: ', IERC20(underlying).balanceOf(alice));
    }
}