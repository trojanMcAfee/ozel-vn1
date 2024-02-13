// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import "../../contracts/Errors.sol";


import "forge-std/console.sol";



contract PauseTest is TestMethods {

    function test_pause_whole_system() public {
        //Pre-condition
        uint ethPrice = OZ.ETH_USD();
        assertTrue(ethPrice > 0);

        //Action
        uint sectionToPause = 1;
        vm.prank(owner);
        OZ.pause(sectionToPause, true);

        //Post-condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        OZ.ETH_USD();
    }

    function test_pause_ozTokens() public {
        
    }

}