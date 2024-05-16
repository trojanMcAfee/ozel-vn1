// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract MyTest_Contract {
    modifier whenUsingBoth6_decAnd18_decUnderlyings() {
        _;
    }

    function test_GivenThereIsOneOzTokenHolder() external whenUsingBoth6_decAnd18_decUnderlyings {
        // it should have same balances for both ozTokens if minting equal amounts.
    }

    function test_GivenThereAreTwoOzTokenHolders() external whenUsingBoth6_decAnd18_decUnderlyings {
        // it should have same balances between holders for both ozTokens if minting equal amounts.
    }
}
