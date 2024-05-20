// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {ozIToken} from "../../../../../../contracts/interfaces/ozIToken.sol";
import {BalanceOf_Core} from "./BalanceOf_Core.sol";

contract BalanceOf_Unit_Concrete_test is BalanceOf_Core {

    ozIToken ozERC20_2;
    ozIToken ozERC20_1; //check if these are needed 


    function test_WhenTotalSupplyIs0() external {
        it_should_return_0(6, Variants.FIRST);
        it_should_return_0(18, Variants.FIRST);
    }

    modifier whenTotalSupplyIsMoreThan0() {
        _;
    }

    function test_GivenThatUserIsAnOzTokenHolder() external whenTotalSupplyIsMoreThan0 {
        it_should_return_a_delta_of_less_than_2_bps(6);
        it_should_return_a_delta_of_less_than_2_bps(18);
    }

    function test_GivenThatTwoUsersAreEqualOzTokenHolders() external whenTotalSupplyIsMoreThan0 {
        it_should_return_the_same_balance_for_both(6);
        it_should_return_the_same_balance_for_both(18);
    }

    function test_GivenThatUserIsNotAnOzTokenHolder() external whenTotalSupplyIsMoreThan0 {
        it_should_return_0(6, Variants.SECOND);
        it_should_return_0(18, Variants.SECOND);
    }

    modifier whenUsingTwoOzTokensOf6DecAnd18DecUnderlyings() {
        _;
    }

    function test_GivenThereIsOneOzTokenHolder() external whenUsingTwoOzTokensOf6DecAnd18DecUnderlyings {
        // it should have same balances for both ozTokens if minting equal amounts.
        it_should_have_same_balances_for_both_ozTokens_if_minting_equal_amounts(ozERC20_1, ozERC20_2);
    }

    function test_GivenThereAreTwoOzTokenHolders() external whenUsingTwoOzTokensOf6DecAnd18DecUnderlyings {
        // it should have same balances between holders for both ozTokens if minting equal amounts.
    }
}
