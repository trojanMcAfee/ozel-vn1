// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";


contract CoreTokenLogicFRXtest is TestMethods {

    function test_minting_approve_smallMint_frax() public {
        _minting_approve_smallMint();
    }

    function test_minting_approve_bigMint_frax() public {
        _minting_approve_bigMint();
    }

}