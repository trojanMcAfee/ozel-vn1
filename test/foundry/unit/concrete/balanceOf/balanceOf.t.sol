// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract BalanceOf_Unit_Concrete_test {
    modifier whenTheUnderlyingHas6Decimals() {
        _;
    }

    function test_GivenTotalSupplyEquals0_6() external whenTheUnderlyingHas6Decimals {
        // it should return 0.
    }

    function test_GivenTotalSupplyIsMoreThan0_6() external whenTheUnderlyingHas6Decimals {
        // it should return more than 0 for an ozToken holder.
        // it should return 0 for an ozToken non-holder.
        // it should return the same balance for two equal ozToken holders.
    }

    modifier whenTheUnderlyingHas18Decimals() {
        _;
    }

    function test_GivenTotalSupplyEquals0_18() external whenTheUnderlyingHas18Decimals {
        // it should return 0.
    }

    function test_GivenTotalSupplyIsMoreThan0_18() external whenTheUnderlyingHas18Decimals {
        // it should return more than 0 for an ozToken holder.
        // it should return 0 for an ozToken non-holder.
        // it should return the same balance for two equal ozToken holders.
    }
}
