// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SharedConditions} from "../SharedConditions.sol";


contract BalanceOf_Core is SharedConditions {

    enum Variants {
        FIRST,
        SECOND
    }

    function it_should_return_0(uint decimals_, Variants v_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(testToken_internal).decimals(), decimals_);
        assertEq(ozERC20.totalSupply(), 0);

        if (v_ == Variants.SECOND) {
            //Conditional action 
            uint amountIn = (rawAmount / 3) * 10 ** IERC20(testToken_internal).decimals();

            _mintOzTokens(ozERC20, bob, testToken_internal, amountIn);

            //Conditional post-condition
            assertTrue(
                _checkPercentageDiff(_toggle(amountIn, decimals_), ozERC20.balanceOf(bob), 2)
            );
        }

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), 0);
    }

    function it_should_return_a_delta_of_less_than_2_bps(uint decimals_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(testToken_internal).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(testToken_internal).decimals();

        //Action
        _mintOzTokens(ozERC20, alice, testToken_internal, amountIn);

        //Post-condition
        assertTrue(
            _checkPercentageDiff(_toggle(amountIn, decimals_), ozERC20.balanceOf(alice), 2)
        );
    }


    function it_should_return_the_same_balance_for_both(uint decimals_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(testToken_internal).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(testToken_internal).decimals();

        //Actions
        _mintOzTokens(ozERC20, alice, testToken_internal, amountIn);
        _mintOzTokens(ozERC20, bob, testToken_internal, amountIn);

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), ozERC20.balanceOf(bob));
    }

}