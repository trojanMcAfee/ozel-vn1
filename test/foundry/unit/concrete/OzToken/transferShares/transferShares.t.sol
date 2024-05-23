// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {TransferShares_Core} from "./TransferShares_Core.sol";

contract TransferShares_Unit_Concrete_test is TransferShares_Core {
    function test_WhenSenderHasTheNecessaryShares() external {
        it_should_transfer_shares_and_emit_events(6);
        // it_should_transfer_shares_and_emit_events(18);
    }

    function test_RevertOn_WhenSenderDoesntHaveTheNecessaryShares() external {
        it_should_throw_error_07(6);
        it_should_throw_error_07(18);
    }

    function test_RevertOn_WhenRecipientIsZero() external {
        it_should_throw_error_04(6);
        it_should_throw_error_04(18);
    }

    function test_RevertOn_WhenRecipientIsSelf() external {
        it_should_throw_error_42(6);
        it_should_throw_error_42(18);
    }
}
