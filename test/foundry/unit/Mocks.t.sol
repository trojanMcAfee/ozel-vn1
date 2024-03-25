// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {MockStorage} from "./MockStorage.sol";

import "forge-std/console.sol";


contract MocksTests is MockStorage, TestMethods {

    

    function test_chainlink_feeds() public {
        uint mockPriceRETH = OZ.rETH_ETH();
        assertTrue(mockPriceRETH == rETHPreAccrual);

        // uint mockPriceETH = OZ.ETH_USD();
        // assertTrue(mockPriceETH == currentPriceETH);
    }



}