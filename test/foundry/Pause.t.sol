// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";


import "forge-std/console.sol";



contract PauseTest is TestMethods {

    function test_pause_whole_system() public {
        uint ethPrice = OZ.ETH_USD();
        assertTrue(ethPrice > 0);

    }

}