// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Mock} from "../../../../base/AppStorageTests.sol";
import {SharedConditions} from "../SharedConditions.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";


contract TotalSupply_Core is SharedConditions {

    function it_should_return_0(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        assertEq(ozERC20.totalShares(), 0);

        //Post-condition
        assertEq(ozERC20.totalSupply(), 0);
    }

    function it_should_return_the_sum_of_all_users_balances(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        
        uint rawAmount = 100;
        _mock_rETH_ETH_unit(Mock.PREACCRUAL_UNI_NO_DEVIATION);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        //Actions
        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        _mintOzTokens(ozERC20, bob, underlying, amountIn);

        //Post-condition
        assertEq(
            ozERC20.balanceOf(bob) + ozERC20.balanceOf(alice),
            ozERC20.totalSupply()
        );
    }

}