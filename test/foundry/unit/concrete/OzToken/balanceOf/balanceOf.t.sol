// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {ozIToken} from "../../../../../../contracts/interfaces/ozIToken.sol";
import {BalanceOf_Core} from "./BalanceOf_Core.sol";

contract BalanceOf_Unit_Concrete_test is BalanceOf_Core {

    ozIToken ozERC20_2;
    ozIToken ozERC20_1;


    function test_WhenTotalSupplyIs0() external {
        it_should_return_0(6, Variants.FIRST);
        it_should_return_0(18, Variants.FIRST);
    }

    modifier whenTotalSupplyIsMoreThan0() {
        _;
    }

    function test_GivenThatUserIsAnOzTokenHolder() external whenTotalSupplyIsMoreThan0 {
        it_should_return_a_delta_of_less_than_2_bps(6);
        // it should return a delta less than 2 bps_18dec
    }

    function test_GivenThatTwoUsersAreEqualOzTokenHolders() external whenTotalSupplyIsMoreThan0 {
        // it should return the same balance for both_6dec.
    }

    function test_GivenThatUserIsNotAnOzTokenHolder() external whenTotalSupplyIsMoreThan0 {
        // it should return 0_6dec
        // it should return 0_18dec
    }

    modifier whenUsingTwoOzTokensOf6DecAnd18DecUnderlyings() {
        _;
    }

    function test_GivenThereIsOneOzTokenHolder() external whenUsingTwoOzTokensOf6DecAnd18DecUnderlyings {
        // it should have same balances for both ozTokens if minting equal amounts.
    }

    function test_GivenThereAreTwoOzTokenHolders() external whenUsingTwoOzTokensOf6DecAnd18DecUnderlyings {
        // it should have same balances between holders for both ozTokens if minting equal amounts.
    }
}
