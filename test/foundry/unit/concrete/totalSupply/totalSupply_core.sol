// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TestMethods} from "../../../base/TestMethods.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Mock} from "../../../base/AppStorageTests.sol";

import {console} from "forge-std/console.sol";

contract TotalSupply_Core is TestMethods {

    function it_should_return_0(ozIToken ozERC20_, uint decimals_) internal view {
        //Pre-conditions
        assertEq(IERC20(ozERC20_.asset()).decimals(), decimals_);
        assertEq(ozERC20_.totalShares(), 0);

        //Post-condition
        assertEq(ozERC20_.totalSupply(), 0);
    }

    function it_should_return_the_sum_of_all_users_balances(ozIToken ozERC20_, uint decimals_) internal {
        //Pre-conditions
        assertEq(IERC20(ozERC20_.asset()).decimals(), decimals_);

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        address testToken_internal = ozERC20_.asset();

        _mock_rETH_ETH_unit(Mock.PREACCRUAL_UNI_NO_DEVIATION);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(testToken_internal).decimals();

        //Actions
        _mintOzTokens(ozERC20_, alice, testToken_internal, amountIn);
        _mintOzTokens(ozERC20_, bob, testToken_internal, amountIn);

        //Post-condition
        assertEq(
            ozERC20_.balanceOf(bob) + ozERC20_.balanceOf(alice),
            ozERC20_.totalSupply()
        );
    }

}