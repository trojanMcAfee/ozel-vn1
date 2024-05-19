// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TotalSupply_Core} from "./totalSupply_core.sol";


contract TotalSupply_Unit_Concrete_Test is TotalSupply_Core {

    function test_GivenTotalSharesEqual0_6() external whenTheUnderlyingHas6Decimals {
        it_should_return_0(6);
    }

    function test_GivenTotalSharesIsNotEqualTo0_6() external whenTheUnderlyingHas6Decimals {
        it_should_return_the_sum_of_all_users_balances(6);
    }

    function test_GivenTotalSharesEqual0_18() external whenTheUnderlyingHas18Decimals {
        it_should_return_0(18);
    }

    function test_GivenTotalSharesIsNotEqualTo0_18() external whenTheUnderlyingHas18Decimals {
        it_should_return_the_sum_of_all_users_balances(18);
    }
}
