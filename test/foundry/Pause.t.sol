// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import "../../contracts/Errors.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";


import "forge-std/console.sol";



contract PauseTest is TestMethods {

    //tests that the owner can pause the whole system
    function test_pause_whole_system() public {
        //Pre-condition
        uint ethPrice = OZ.ETH_USD();
        assertTrue(ethPrice > 0);

        //Action
        uint sectionToPause = 2;
        vm.prank(owner);
        OZ.pause(sectionToPause, true);

        //Post-condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        OZ.ETH_USD();
    }

    //tests that the owner can pause any interactions with any ozToken
    function test_pause_ozTokens_and_checks_enable_switch() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (ozIToken ozERC20_2,) = _createOzTokens(secondTestToken, "2");

        uint decimals = ozERC20.decimals();
        uint decimals_2 = ozERC20_2.decimals();
        assertTrue(decimals > 0);
        assertTrue(decimals_2 > 0);

        //Action
        uint sectionToPause = 3;
        vm.prank(owner);
        OZ.pause(sectionToPause, true);

        //Post-conditions
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        ozERC20.decimals();

        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        ozERC20_2.decimals();

        uint price = OZ.ETH_USD();
        assertTrue(price > 0);
        assertTrue(OZ.getEnabledSwitch());
    }

    //Tests that you can't pause the system once the enabled switch is false
    function test_pause_attempt_switch_disabled() public {
        //Pre-conditions
        uint price = OZ.ETH_USD();
        assertTrue(price > 0);

        //Action
        vm.startPrank(owner);
        bool newSwitchState = OZ.enableSwitch(false);
        assertTrue(!newSwitchState);

        //Post-conditions
        uint sectionToPause = 2;
        vm.expectRevert(
            abi.encodeWithSelector(OZError30.selector)
        );
        OZ.pause(sectionToPause, true);

        assertTrue(!OZ.getEnabledSwitch());
    }

    //Tests that the ozTokens factory can be paused, but not the rest of contracts
    function test_pause_factory() public {
        //Pre-conditions
        _createOzTokens(testToken, "1");

        uint sectionToPause = 4;
        vm.prank(owner);

        //Action
        bool isPaused = OZ.pause(sectionToPause, true);
        assertTrue(isPaused);

        //Post-conditions
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        _createOzTokens(secondTestToken, "2");

        uint price = OZ.ETH_USD();
        assertTrue(price > 0);
    }

}