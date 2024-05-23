// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TransferShares_Core} from "./TransferShares_Core.sol";


contract TransferShares_Unit_Concrete_test is TransferShares_Core {
    function test_WhenSenderHasTheNecessaryShares() external {
        it_should_transfer_shares(6);
        it_should_transfer_shares(18);
    }

    function test_WhenSenderDoesntHaveTheNecessaryShares() external {
        // it should throw error_6dec.
        // it should throw error_18dec.
    }

    function test_WhenRecipientIsZero() external {
        // it should throw error.
    }

    function test_WhenRecipientIsSelf() external {
        // it should throw error.
    }
}
