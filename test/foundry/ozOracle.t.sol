// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";


contract ozOracleTest is TestMethods {

    function test_ETH_USD() public {

        uint ethPrice = OZ.ETH_USD();
        console.log('ethPrice in test: ', ethPrice);

    }




}