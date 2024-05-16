// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SharedConditions} from "../SharedConditions.sol";

import {console} from "forge-std/console.sol";


contract BalanceOf_Core is SharedConditions {

    function it_should_return_0(uint decimals_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(ozERC20.asset()).decimals(), decimals_);
        assertEq(ozERC20.totalSupply(), 0);

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), 0);
    }

    function it_should_return_a_delta_of_less_than_2_bps(uint decimals_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(testToken_internal).decimals(), decimals_);

        uint rawAmount = 100;
        uint amountIn = (rawAmount / 3) * 10 ** IERC20(testToken_internal).decimals();

        //Action
        _mintOzTokens(ozERC20, alice, testToken_internal, amountIn);

        //Post-condition
        assertTrue(
            _checkPercentageDiff(_toggle(amountIn, decimals_), ozERC20.balanceOf(alice), 2)
        );
    }


    function it_should_return_the_same_balance_for_both() skipOrNot internal {

    }

}