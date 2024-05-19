// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {Mint_Core} from "./Mint_Core.sol";


contract Mint_Unit_Concrete_test is Mint_Core {

    function test_RevertOn_WhenOwnerIsZero() external {
        it_should_revert(6, Revert.OWNER);
        it_should_revert(18, Revert.OWNER);
    }

    modifier whenAnalysingMintData() {
        _;
    }

    function test_RevertOn_WhenAmountInIsZero() external whenAnalysingMintData {
        it_should_revert(6, Revert.AMOUNT_IN);
        it_should_revert(18, Revert.AMOUNT_IN);
    }

    function test_RevertOn_WhenReceiverIsZero() external whenAnalysingMintData {
        it_should_revert(6, Revert.RECEIVER);
        it_should_revert(18, Revert.RECEIVER);
    }

    function test_RevertOn_WhenMintDataIsNotProperlyEncoded() external whenAnalysingMintData {
        it_should_throw_error_39(6);
        it_should_throw_error_39(18);
    }

    function test_WhenUserHasUnderlyingBalance() external {
        it_should_mint(6);
        it_should_mint(18);
    }

    function test_RevertOn_WhenUserDoesntHaveUnderlyingBalance() external {
        it_should_throw_error_22(6);
        it_should_throw_error_22(18);
    }

    function test_RevertOn_WhenYouTryToReenter() external {
        it_should_revert(6, Revert.REENTRANT);
    }
}
