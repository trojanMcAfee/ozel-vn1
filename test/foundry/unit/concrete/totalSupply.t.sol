// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract totalSupply_Unit_Concrete_Test {
    modifier whenTheUnderlyingHas6Decimals() {
        _;
    }

    function test_GivenTotalSharesEqual0_6() external whenTheUnderlyingHas6Decimals {
        // it should return 0.
    }

    function test_GivenTotalSharesIsNotEqualTo0_6() external whenTheUnderlyingHas6Decimals {
        // it should return the sum of all users' balances.
    }

    modifier whenTheUnderlyingHas18Decimals() {
        _;
    }

    function test_GivenTotalSharesEqual0() external whenTheUnderlyingHas18Decimals {
        // it should return 0.
    }

    function test_GivenTotalSharesIsNotEqualTo0() external whenTheUnderlyingHas18Decimals {
        // it should return the sum of all users' balances.
    }
}
