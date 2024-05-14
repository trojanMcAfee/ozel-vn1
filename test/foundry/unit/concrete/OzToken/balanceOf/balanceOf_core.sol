// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SharedConditions} from "../SharedConditions.sol";


contract BalanceOf_Core is SharedConditions {

    function it_should_return_0(uint decimals_) skipOrNot internal {
        //Pre-conditions
        assertEq(IERC20(ozERC20.asset()).decimals(), decimals_);
        assertEq(ozERC20.totalSupply(), 0);

        //Post-condition
        assertEq(ozERC20.balanceOf(alice), 0);
    }

    function it_should_return_more_than_0() skipOrNot internal {

    }

    function it_should_return_the_same_balance_for_both() skipOrNot internal {

    }

}