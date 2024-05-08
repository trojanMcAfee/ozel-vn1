// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TestMethods} from "../../../base/TestMethods.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


contract TotalSupply_Core is TestMethods {

    function it_should_return_0(ozIToken ozERC20_, uint decimals_) internal view {
        //Pre-conditions
        assertEq(IERC20(ozERC20_.asset()).decimals(), decimals_);
        assertEq(ozERC20_.totalShares(), 0);

        //Post-condition
        assertEq(ozERC20_.totalSupply(), 0);
    }

    //finish this (terminal) and run this test ------------------->
    function it_should_return_the_sum_of_all_users_balances(ozIToken ozERC20_, uint decimals_) internal {
        //Pre-conditions
        assertEq(IERC20(ozERC20_.asset()).decimals(), decimals_);

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        address testToken_internal = ozERC20_.asset();

        _mock_rETH_ETH_unit(Mock.PREACCRUAL_UNI_NO_DEVIATION);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken_internal).decimals();

        //Actions
        _mintOzTokens(ozERC20, alice, testToken_internal, amountIn);
        _mintOzTokens(ozERC20, bob, testToken_internal, amountIn);

        //Post-condition
        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        assertEq(ozERC20.balanceOf(bob) + ozBalanceAlice, ozERC20.totalSupply());
    }

}