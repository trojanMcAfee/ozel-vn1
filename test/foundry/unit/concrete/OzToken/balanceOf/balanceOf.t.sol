// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {BalanceOf_Core} from "./BalanceOf_Core.sol";


contract BalanceOf_Unit_Concrete_test is BalanceOf_Core {

    function test_GivenTotalSupplyEquals0_6() external whenTheUnderlyingHas6Decimals {
        it_should_return_0(6, Variants.FIRST);
    }

    modifier whenTotalSupplyIsMoreThan0_6() {
        _;
    }

    function test_GivenThatUserIsAnOzTokenHolder_6()
        external
        whenTheUnderlyingHas6Decimals
        whenTotalSupplyIsMoreThan0_6
    {
        it_should_return_a_delta_of_less_than_2_bps(6);
    }

    function test_GivenThatTwoUsersAreEqualOzTokenHolders_6()
        external
        whenTheUnderlyingHas6Decimals
        whenTotalSupplyIsMoreThan0_6
    {
        it_should_return_the_same_balance_for_both(6);
    }

    function test_GivenThatUserIsNotAnOzTokenHolder_6()
        external
        whenTheUnderlyingHas6Decimals
        whenTotalSupplyIsMoreThan0_6
    {
        it_should_return_0(6, Variants.SECOND);
    }


    function test_GivenTotalSupplyEquals0_18() external whenTheUnderlyingHas18Decimals {
        // it should return 0.
    }

    modifier whenTotalSupplyIsMoreThan0_18() {
        _;
    }

    function test_GivenThatUserIsAnOzTokenHolder_18()
        external
        whenTheUnderlyingHas18Decimals
        whenTotalSupplyIsMoreThan0_18
    {
        // it should return more than 0.
    }

    function test_GivenThatTwoUsersAreEqualOzTokenHolders_18()
        external
        whenTheUnderlyingHas18Decimals
        whenTotalSupplyIsMoreThan0_18
    {
        // it should return the same balance for both.
    }

    function test_GivenThatUserIsNotAnOzTokenHolder_18()
        external
        whenTheUnderlyingHas18Decimals
        whenTotalSupplyIsMoreThan0_18
    {
        // it should return 0.
    }
}
