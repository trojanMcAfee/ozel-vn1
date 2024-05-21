// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {Redeem_Core} from "./Redeem_Core.sol";

contract Redeem_Unit_Concrete_test is Redeem_Core {

    function test_WhenOwnerIsZero() external {
        it_should_revert(6); 
        it_should_revert(18);    
    }

    modifier whenAnalysingRedeemData() {
        _;
    }

    function test_RevertOn_WhenOzAmountInIsMoreThanUsersBalance() external whenAnalysingRedeemData {
        it_should_throw_error_06(6);
        it_should_throw_error_06(18);
    }

    function test_WhenOzTokenIsInvalid() external whenAnalysingRedeemData {
        // it should throw error_6dec.
        // it should throw error_18dec.
    }

    function test_WhenReceiverIsZero() external whenAnalysingRedeemData {
        // it should revert_6dec.
        // it should revert_18dec.
    }

    function test_WhenInMintDataOwnerIsZero() external whenAnalysingRedeemData {
        // it should revert_6dec.
        // it should revert_18dec.
    }

    function test_WhenRedeemDataIsNotProperlyEncoded() external whenAnalysingRedeemData {
        // it should throw error_6dec.
        // it should throw error_18dec.
    }

    function test_WhenOzAmountInDoesntCorrespondToAmountInReth() external whenAnalysingRedeemData {
        // it should throw error_6dec.
        // it should throw error_18dec.
    }

    function test_WhenYouTryToReenter() external {
        // it should revert.
    }
}
