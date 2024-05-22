// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";
import {OZError06, OZError38, OZError39, OZError40, OZError21} from "./../../../../../../contracts/Errors.sol";
import {MockReentrantVaultBalancer} from "../../../../mocks/balancer/MockReentrantVaultBalancer.sol";
import {AmountsOut} from "./../../../../../../contracts/AppStorage.sol";

import {console} from "forge-std/console.sol";


contract Redeem_Core is SharedConditions {

    function it_should_revert(uint decimals_, Revert type_) internal {
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

        address owner = alice;
        bytes4 selector;

        if (type_ == Revert.OWNER) {
            owner = address(0);
            selector = OZError38.selector;
        } else if (type_ == Revert.REENTRANT) {
            MockReentrantVaultBalancer reentrantVault = new MockReentrantVaultBalancer(ozERC20);
            vm.etch(vaultBalancer, address(reentrantVault).code);
            selector = OZError40.selector;
        }

        //Action + Post-Condition
        vm.expectRevert(
            abi.encodeWithSelector(selector)
        );
        ozERC20.redeem(data, owner);
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
        assertGt(ozERC20.balanceOf(alice), 0);

        uint underlyingBalanceAlicePreRedeem = IERC20(underlying).balanceOf(alice);

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, 
            address(ozERC20), 
            OZ.getDefaultSlippage(), 
            alice, 
            alice
        );

        //Actions
        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);
        ozERC20.redeem(data, alice);

        //Post-conditions
        assertEq(ozERC20.balanceOf(alice), 0);
        assertGt(IERC20(underlying).balanceOf(alice), underlyingBalanceAlicePreRedeem);

        //Also, check that the stables are properly deducted in the mint test
    }


    function it_should_throw_error_21(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);

        uint ozAmountIn = ozERC20.balanceOf(alice);

        AmountsOut memory amts = OZ.quoteAmountsOut(
            ozAmountIn, 
            address(ozERC20),
            OZ.getDefaultSlippage(),
            alice
        );

        amts.amountInReth *= 2;
        bytes memory data = abi.encode(amts, alice);

        //Actions
        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);

        vm.expectRevert(
            abi.encodeWithSelector(OZError21.selector, "ERC20: transfer amount exceeds balance")
        );
        ozERC20.redeem(data, alice);
    }
}