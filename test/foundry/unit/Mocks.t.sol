// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {MockStorage} from "./MockStorage.sol";

import "forge-std/console.sol";


contract MocksTests is MockStorage, TestMethods {

    

    function test_rETH_ETH() public {
        uint mockPrice = OZ.rETH_ETH();
        assertTrue(mockPrice == rETHPreAccrual);
    }



}