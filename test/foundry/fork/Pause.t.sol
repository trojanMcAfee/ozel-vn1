// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../base/TestMethods.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {wozIToken} from "../../../contracts/interfaces/wozIToken.sol";
import {IOZL} from "../../../contracts/interfaces/IOZL.sol";
import "../../../contracts/Errors.sol";


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

    //Tests that wozTokens can be paused
    function test_pause_wozTokens() public {
        //Pre-condition
        (,wozIToken wozERC20) = _createOzTokens(testToken, "1");
        assertTrue(wozERC20.asset() != address(0));

        //Action
        uint sectionToPause = 3;
        vm.prank(owner);
        OZ.pause(sectionToPause, true);

        //Post-condtion
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        wozERC20.asset();
    }

    //Tests that you can't add as a pause facet, a contract that doesn't exist in ozDiamond
    function test_cant_add_nonExistent_pause_facet() public {
        //Pre-condition
        address facetToAdd = address(1);
        
        //Action + Post-condtion
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(OZError31.selector, facetToAdd)
        );
        OZ.addPauseContract(facetToAdd);
    }

    //Tests that you can't add address(0) as a pause facet
    function test_cant_add_0_address() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(OZError32.selector)
        );
        OZ.addPauseContract(address(0));
    }

    //Tests that you can pause OZL through OZLproxy
    function test_pause_OZL() public {
        //Pre-conditions
        uint sectionToPause = 5;
        IOZL OZL = IOZL(address(ozlProxy));

        bytes32 rate = OZL.DOMAIN_SEPARATOR();
        assertTrue(rate != bytes32(0));

        //Action
        vm.prank(owner);
        OZ.pause(sectionToPause, true);

        //Post-conditions
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        OZL.DOMAIN_SEPARATOR();

        assertTrue(OZ.ETH_USD() > 0);
    }

    //Adds another contract as another pauseContract, and pauses it.
    function test_add_another_contract_and_pause_it() public {
        //Pre-conditions
        uint fee = OZ.getAdminFee();
        assertTrue(fee > 0);

        //Actions
        vm.startPrank(owner);
        OZ.addPauseContract(address(loupe));

        uint sectionToPause = 6;
        OZ.pause(sectionToPause, true);
        vm.stopPrank();

        //Post-conditions
        vm.expectRevert(
            abi.encodeWithSelector(OZError27.selector, sectionToPause)
        );
        OZ.getAdminFee();

        assertTrue(OZ.ETH_USD() > 0);
    }


    function test_getPausedContracts() public {
        //Pre-conditions
        assertTrue(OZ.getPausedContracts().length == 0);
        uint firstPausedSection = 3;
        uint secondPausedSection = 5;

        //Actions
        vm.startPrank(owner);
        OZ.pause(firstPausedSection, true);
        OZ.pause(secondPausedSection, true);
        vm.stopPrank();

        //Post-conditions
        uint[] memory contracIndexes = OZ.getPausedContracts();
        assertTrue(contracIndexes.length == 2);
        assertTrue(contracIndexes[0] == firstPausedSection);
        assertTrue(contracIndexes[1] == secondPausedSection);
    }

    //Tests pausing and unpausing sections.
    function test_pause_unpause() public {
        //Pre-conditions
        vm.startPrank(owner);
        OZ.pause(4, true);
        OZ.pause(5, true);

        uint[] memory contracIndexes = OZ.getPausedContracts();
        assertTrue(contracIndexes.length == 2);

        //Action
        OZ.pause(4, false);
        vm.stopPrank();

        //Post-conditions
        contracIndexes = OZ.getPausedContracts();
        assertTrue(contracIndexes.length == 1);
    }





}