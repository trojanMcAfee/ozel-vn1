// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../../contracts/interfaces/ozIToken.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SharedConditions} from "../SharedConditions.sol";

import {console} from "forge-std/console.sol";


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
        console.log('testToken_internal: ', testToken_internal);
        assertEq(IERC20(testToken_internal).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(testToken_internal).decimals();

        //Actions
        _mintOzTokens(ozERC20, alice, testToken_internal, amountIn);
        _mintOzTokens(ozERC20, bob, testToken_internal, amountIn);

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), ozERC20.balanceOf(bob));
    }

    function it_should_have_same_balances_for_both_ozTokens_if_minting_equal_amounts(ozIToken ozERC20_1_, ozIToken ozERC20_2_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(ozERC20_1_.asset()).decimals(), 6);
        assertEq(IERC20(ozERC20_2_.asset()).decimals(), 18);

        uint amountIn = (rawAmount / 3) * 10 ** 6;
        uint amountIn_2 = (rawAmount / 3) * 10 ** 18;

        //Actions
        console.log(1);
        _mintOzTokens(ozERC20, alice, testToken_internal, amountIn);
        console.log(2);
        _mintOzTokens(ozERC20_2_, alice, ozERC20_2_.asset(), amountIn_2);
        console.log(3);

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), ozERC20_2_.balanceOf(alice));
    }

}