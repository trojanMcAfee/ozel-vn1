// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TotalSupply_Core} from "./totalSupply_core.sol";
// import {TestMethods} from "../../../base/TestMethods.sol";

import {console} from "forge-std/console.sol";

contract TotalSupply_Unit_Concrete_Test is TotalSupply_Core {
    
    ozIToken ozERC20;

    modifier whenTheUnderlyingHas6Decimals() {
        (ozIToken a,) = _createOzTokens(usdcAddr, "1");
        ozERC20 = a;
        _;
    }


    function test_GivenTotalSharesEqual0_6() external whenTheUnderlyingHas6Decimals {
        it_should_return_0(ozERC20, 6);
    }

    function test_GivenTotalSharesIsNotEqualTo0_6() external whenTheUnderlyingHas6Decimals {
        it_should_return_the_sum_of_all_users_balances(ozERC20, 6);
    }

    modifier whenTheUnderlyingHas18Decimals() {
        (ozIToken a,) = _createOzTokens(daiAddr, "1");
        ozERC20 = a;
        _;
    }


    function test_GivenTotalSharesEqual0_18() external whenTheUnderlyingHas18Decimals {
        it_should_return_0(ozERC20, 18);
    }

    function test_GivenTotalSharesIsNotEqualTo0_18() external whenTheUnderlyingHas18Decimals {
        it_should_return_the_sum_of_all_users_balances(ozERC20, 18);
    }
}
