// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {ozIToken} from "../../../../../../contracts/interfaces/ozIToken.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SharedConditions} from "../SharedConditions.sol";

import {console} from "forge-std/console.sol";


contract BalanceOf_Core is SharedConditions {

    enum Variants {
        FIRST,
        SECOND
    }

    function it_should_return_0(uint decimals_, Variants v_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        assertEq(ozERC20.totalSupply(), 0);

        if (v_ == Variants.SECOND) {
            //Conditional action 
            uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

            _mintOzTokens(ozERC20, bob, underlying, amountIn);

            //Conditional post-condition
            assertTrue(
                _checkPercentageDiff(_toggle(amountIn, decimals_), ozERC20.balanceOf(bob), 2)
            );
        }

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), 0);
    }

    function it_should_return_a_delta_of_less_than_2_bps(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        //Action
        _mintOzTokens(ozERC20, alice, underlying, amountIn);

        //Post-condition
        assertTrue(
            _checkPercentageDiff(_toggle(amountIn, decimals_), ozERC20.balanceOf(alice), 2)
        );
    }


    function it_should_return_the_same_balance_for_both(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        //Actions
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        _mintOzTokens(ozERC20, bob, underlying, amountIn);

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), ozERC20.balanceOf(bob));
    }

    function it_should_have_same_balances_for_both_ozTokens_if_minting_equal_amounts() skipOrNot internal {
        //Pre-conditions
        (ozIToken ozUSDC, ozIToken ozDAI) = _setUpTwoOzTokens();
        assertEq(IERC20(ozUSDC.asset()).decimals(), 6);
        assertEq(IERC20(ozDAI.asset()).decimals(), 18);

        uint amountIn = (rawAmount / 3) * 10 ** 6;
        uint amountIn_2 = (rawAmount / 3) * 10 ** 18;

        //Actions
        _mintOzTokens(ozUSDC, alice, ozUSDC.asset(), amountIn);
        _mintOzTokens(ozDAI, alice, ozDAI.asset(), amountIn_2);

        //Post-condition
        assertEq(ozUSDC.balanceOf(alice), ozDAI.balanceOf(alice));
    }


    function it_should_have_same_balances_between_holders_for_both_ozTokens_if_minting_equal_amounts() public skipOrNot {
        //Pre-conditions
        (ozIToken ozUSDC, ozIToken ozDAI) = _setUpTwoOzTokens();
        assertEq(IERC20(ozUSDC.asset()).decimals(), 6);
        assertEq(IERC20(ozDAI.asset()).decimals(), 18);

        uint amountIn = (rawAmount / 3) * 10 ** 6;
        uint amountIn_2 = (rawAmount / 3) * 10 ** 18;

        //Actions
        _mintOzTokens(ozUSDC, alice, ozUSDC.asset(), amountIn);
        _mintOzTokens(ozDAI, bob, ozDAI.asset(), amountIn_2);

        //Post-condition
        assertEq(ozUSDC.balanceOf(alice), ozDAI.balanceOf(bob));
    }
}