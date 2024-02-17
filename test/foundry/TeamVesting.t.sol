// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";


contract TeamVestingTest is TestMethods {

    function test_x() public {
        console.log('teamVesting addr: ', address(teamVesting));

        uint releasable = teamVesting.releasable();
        console.log('releasable: ', releasable);

        uint vested = teamVesting.vestedAmount(uint64(block.timestamp));
        console.log('vested - 0: ', vested);

    }



}