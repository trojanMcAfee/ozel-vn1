// // SPDX-License-Identifier: GPL-2.0-or-later
// pragma solidity 0.8.24;


// import {ozIToken} from "../../../../../../contracts/interfaces/ozIToken.sol";
// import {BalanceOf_Core} from "./BalanceOf_Core.sol";

// import {console} from "forge-std/console.sol";


// contract BalanceOf_Unit_Concrete_test2 is BalanceOf_Core {

//     ozIToken ozERC20_2;
//     ozIToken ozERC20_1;

//     function test_GivenTotalSupplyEquals0_6() external whenTheUnderlyingHas6Decimals {
//         it_should_return_0(6, Variants.FIRST);
//     }

//     modifier whenTotalSupplyIsMoreThan0_6() {
//         _;
//     }

//     function test_GivenThatUserIsAnOzTokenHolder_6()
//         external
//         whenTheUnderlyingHas6Decimals
//         whenTotalSupplyIsMoreThan0_6
//     {
//         it_should_return_a_delta_of_less_than_2_bps(6);
//     }

//     function test_GivenThatTwoUsersAreEqualOzTokenHolders_6()
//         external
//         whenTheUnderlyingHas6Decimals
//         whenTotalSupplyIsMoreThan0_6
//     {
//         it_should_return_the_same_balance_for_both(6);
//     }

//     function test_GivenThatUserIsNotAnOzTokenHolder_6()
//         external
//         whenTheUnderlyingHas6Decimals
//         whenTotalSupplyIsMoreThan0_6
//     {
        // it_should_return_0(6, Variants.SECOND);
//     }


//     function test_GivenTotalSupplyEquals0_18() external whenTheUnderlyingHas18Decimals {
//         it_should_return_0(18, Variants.FIRST);
//     }

//     modifier whenTotalSupplyIsMoreThan0_18() {
//         _;
//     }

//     function test_GivenThatUserIsAnOzTokenHolder_18()
//         external
//         whenTheUnderlyingHas18Decimals
//         whenTotalSupplyIsMoreThan0_18
//     {
//         it_should_return_a_delta_of_less_than_2_bps(18);
//     }

//     function test_GivenThatTwoUsersAreEqualOzTokenHolders_18()
//         external
//         whenTheUnderlyingHas18Decimals
//         whenTotalSupplyIsMoreThan0_18
//     {
//         it_should_return_the_same_balance_for_both(18);
//     }

//     function test_GivenThatUserIsNotAnOzTokenHolder_18()
//         external
//         whenTheUnderlyingHas18Decimals
//         whenTotalSupplyIsMoreThan0_18
//     {
//         it_should_return_0(18, Variants.SECOND);
//     }

//     modifier whenUsingBoth6_decAnd18_decUnderlyings() {
//         (ozIToken a,) = _createOzTokens(usdcAddr, "1");
//         ozERC20_1 = a;

//         (ozIToken b,) = _createOzTokens(daiAddr, "2");
//         ozERC20_2 = b;
//         _;
//     }

//     function test_GivenThereIsOneOzTokenHolder() external whenUsingBoth6_decAnd18_decUnderlyings {
        // it_should_have_same_balances_for_both_ozTokens_if_minting_equal_amounts(ozERC20_1, ozERC20_2);
//     }

//     function test_GivenThereAreTwoOzTokenHolders() external whenUsingBoth6_decAnd18_decUnderlyings {
        // it_should_have_same_balances_between_holders_for_both_ozTokens_if_minting_equal_amounts(ozERC20_1, ozERC20_2);
//     }
// }
