// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TestMethods} from "../../../base/TestMethods.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


contract TotalSupply_Core is TestMethods {

    function it_should_return_0(ozIToken ozERC20_, uint decimals_) internal view {
        //Pre-conditions
        assertEq(ozERC20_.totalShares(), 0);
        assertEq(IERC20(ozERC20_.asset()).decimals(), decimals_);

        //Post-condition
        assertEq(ozERC20_.totalSupply(), 0);
    }

}