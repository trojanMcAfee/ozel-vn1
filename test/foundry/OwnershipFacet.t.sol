// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import "../../contracts/Errors.sol";
import {ozToken} from "../../contracts/ozToken.sol";
import {wozToken} from "../../contracts/wozToken.sol";

import "forge-std/console.sol";



contract OwnershipFacetTest is TestMethods {

    function test_fail_noOwner_cant_transfer_ownership() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(OZError33.selector, alice)
        );

        OZ.transferOwnershipDiamond(alice);
    }

    function test_change_ownership_2step() public {
        //Pre-conditions
        vm.prank(owner);
        OZ.transferOwnershipDiamond(alice);

        assertTrue(OZ.pendingOwner() == alice);

        //Action
        vm.prank(alice);
        OZ.acceptOwnership();

        //Post-condition
        assertTrue(OZ.ownerDiamond() == alice);
    }

    function test_change_ownership_missing_1step() public {
        //Pre-condition
        assertTrue(OZ.ownerDiamond() == owner);

        //Action
        vm.prank(owner);
        OZ.transferOwnershipDiamond(alice);

        //Post-conditions
        assertTrue(OZ.ownerDiamond() == owner);
        assertTrue(OZ.pendingOwner() == alice);
    }

    function test_renounce_ownership() public {
        //Pre-condition
        assertTrue(OZ.ownerDiamond() == owner);

        //Action
        vm.prank(owner);
        OZ.renounceOwnership();

        //Post-condition
        assertTrue(OZ.ownerDiamond() == address(0));
    }

    function test_change_oz_woz_implementations() public {
        address[] memory newImplementations = new address[](2);
        ozToken newOzImpl = new ozToken();
        wozToken newWozImpl = new wozToken();
        newImplementations[0] = address(newOzImpl);
        newImplementations[1] = address(newWozImpl);

        address[] memory implementations = OZ.getOzImplementations();

        for (uint i=0; i < implementations.length; i++) {
            assertTrue(implementations[i] != newImplementations[i]);
        }
        
        vm.prank(owner);
        OZ.changeOzTokenImplementations(newImplementations);

        implementations = OZ.getOzImplementations();

        for (uint i=0; i < implementations.length; i++) {
            assertTrue(implementations[i] == newImplementations[i]);
        }
    }

}