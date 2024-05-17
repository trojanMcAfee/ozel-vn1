// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Mint_Unit_Concrete_test2 {
    function test_WhenAmountIsZero() external {
        // it should revert_6dec
        // it should revert_18dec
    }

    function test_WhenUnderlyingIsZero() external {
        // it should revert_6dec
        // it should revert_18dec
    }

    function test_WhenUnderlyingIsAnOzToken() external {
        // it should mint_6dec
        // it should mint_18dec
    }

    function test_WhenUnderlyingIsNotAnOzToken() external {
        // it should revert_6dec
        // it should revert_18dec
    }
}
