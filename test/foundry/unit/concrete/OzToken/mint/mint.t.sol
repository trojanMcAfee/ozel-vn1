// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Mint_Core} from "./Mint_Core.sol";


contract Mint_Unit_Concrete_test is Mint_Core {
    function test_WhenOwnerIsZero() external {
        it_should_revert(6, Revert.OWNER);
        it_should_revert(18, Revert.OWNER);
    }

    modifier whenAnalysingMintData() {
        _;
    }

    modifier whenAnalysingMinAmountsOut() {
        _;
    }

    function test_WhenAtLeastOneElementFromMinAmountsOutIsZero()
        external
        whenAnalysingMintData
        whenAnalysingMinAmountsOut
    {
        // it should mint with slippage_6dec
        // it should mint with slippage_18dec
    }

    function test_WhenAtLeastOneElementMinAmountsOutIsUintMax()
        external
        whenAnalysingMintData
        whenAnalysingMinAmountsOut
    {
        // it should throw error_6dec
        // it should throw error_18dec
    }

    function test_WhenAmountInIsZero() external whenAnalysingMintData {
        it_should_revert(6, Revert.AMOUNT_IN);
        it_should_revert(18, Revert.AMOUNT_IN);
    }

    function test_WhenSlippageIsNotEnough() external whenAnalysingMintData {
        // it should throw error_6dec
        // it should throw error_18dec
    }

    function test_WhenReceiverIsZero() external whenAnalysingMintData {
        // it should revert_6dec
        // it should revert_18dec
    }

    function test_WhenMintDataIsNotProperlyEncoded() external whenAnalysingMintData {
        // it should throw error_6dec
        // it should throw error_18dec
    }

    function test_WhenUserHasUnderlyingBalance() external {
        // it should mint_6dec
        // it should mint_18dec
    }

    function test_WhenUserDoesntHaveUnderlyingBalance() external {
        // it should throw error_6dec
        // it should throw error_18dec
    }
}
