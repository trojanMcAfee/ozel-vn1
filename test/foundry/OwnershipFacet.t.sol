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

    function test_change_oz_implementation_only() public {
        address[] memory newImplementations = new address[](2);
        ozToken newOzImpl = new ozToken();
        newImplementations[0] = address(newOzImpl);

        console.log('newOzImpl: ', address(newOzImpl));

        _changeAndCheckImplementations(newImplementations);
    }

    function test_change_woz_implementation_only() public { //not working ***
        address[] memory newImplementations = new address[](2);
        wozToken newWozImpl = new wozToken();
        newImplementations[1] = address(newWozImpl);

        _changeAndCheckImplementations(newImplementations);
    }

    function test_change_oz_woz_implementations() public {
        address[] memory newImplementations = new address[](2);
        ozToken newOzImpl = new ozToken();
        wozToken newWozImpl = new wozToken();
        newImplementations[0] = address(newOzImpl);
        newImplementations[1] = address(newWozImpl);

        _changeAndCheckImplementations(newImplementations);
    }


    function _changeAndCheckImplementations(address[] memory newImplementations_) internal {
        address[] memory implementations = OZ.getOzImplementations();

        console.log('');
        console.log('*** old impl ***');

        for (uint i=0; i < implementations.length; i++) {
            console.log('implementations ', i, ': ', implementations[i]);
            assertTrue(implementations[i] != newImplementations_[i]);
        }

        console.log('');
        console.log('*** new impl ***');
        
        vm.prank(owner);
        OZ.changeOzTokenImplementations(newImplementations_);

        implementations = OZ.getOzImplementations();
        assertTrue(implementations.length == 2);
        // console.log('l: ', implementations.length);

        // for (uint i=0; i < implementations.length; i++) {
            // console.log('implementations ', i, ': ', implementations[i]);
            assertTrue(implementations[0] == newImplementations_[0]);
        // }
    }

}