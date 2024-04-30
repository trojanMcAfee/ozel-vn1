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

        assertTrue(OZ.pendingOwnerDiamond() == alice);

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
        assertTrue(OZ.pendingOwnerDiamond() == alice);
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
        uint index = 0;
        address[] memory newImplementations = new address[](2);
        ozToken newOzImpl = new ozToken();
        newImplementations[index] = address(newOzImpl);

        _changeAndCheckImplementations(newImplementations, index);
    }

    function test_change_woz_implementation_only() public { 
        uint index = 1;
        address[] memory newImplementations = new address[](2);
        wozToken newWozImpl = new wozToken();
        newImplementations[index] = address(newWozImpl);

        _changeAndCheckImplementations(newImplementations, index);
    }

    function test_change_oz_woz_implementations() public {
        address[] memory newImplementations = new address[](2);
        ozToken newOzImpl = new ozToken();
        wozToken newWozImpl = new wozToken();
        newImplementations[0] = address(newOzImpl);
        newImplementations[1] = address(newWozImpl);

        _changeAndCheckImplementations(newImplementations, 2);
    }

    function test_fail_change_implementations_addressZero() public {
        address[] memory newImplementations = new address[](2);
        newImplementations[0] = address(0);
        newImplementations[1] = address(0);

        address[] memory implementations = OZ.getOzImplementations();

        for (uint i=0; i < implementations.length; i++) {
            assertTrue(implementations[i] != newImplementations[i]);
        }
        
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(OZError32.selector)
        );
        OZ.changeOzTokenImplementations(newImplementations);
    }

    function test_fail_change_ozImpl_not_contract() public {
        address[] memory newImplementations = new address[](2);
        newImplementations[0] = address(1);
        newImplementations[1] = address(0);

        address[] memory implementations = OZ.getOzImplementations();

        for (uint i=0; i < implementations.length; i++) {
            assertTrue(implementations[i] != newImplementations[i]);
        }
        
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(OZError24.selector)
        );
        OZ.changeOzTokenImplementations(newImplementations);
    }

    function test_fail_change_wozImpl_not_contract() public {
        address[] memory newImplementations = new address[](2);
        newImplementations[0] = address(0);
        newImplementations[1] = address(1);

        address[] memory implementations = OZ.getOzImplementations();

        for (uint i=0; i < implementations.length; i++) {
            assertTrue(implementations[i] != newImplementations[i]);
        }
        
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(OZError24.selector)
        );
        OZ.changeOzTokenImplementations(newImplementations);
    }


    //----------

    function _changeAndCheckImplementations(address[] memory newImplementations_, uint index_) internal {
        address[] memory implementations = OZ.getOzImplementations();

        for (uint i=0; i < implementations.length; i++) {
            assertTrue(implementations[i] != newImplementations_[i]);
        }
        
        vm.prank(owner);
        OZ.changeOzTokenImplementations(newImplementations_);

        implementations = OZ.getOzImplementations();

        if (index_ != 2) {
            assertTrue(implementations.length == 2);
            assertTrue(implementations[index_] == newImplementations_[index_]);
        } else {
            for (uint i=0; i < implementations.length; i++) {
                assertTrue(implementations[i] == newImplementations_[i]);
            }
        }
    }

    function test_get_OZLadmin() public {
    assertTrue(OZ.ownerOZL() == OZ.getOZLadmin());
    }



}