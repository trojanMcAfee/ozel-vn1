// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import "../../contracts/Errors.sol";



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

    function test_fail_change_ownership_missing_1step() public {
        //Pre-condition
        assertTrue(OZ.ownerDiamond() == owner);

        //Action
        vm.prank(owner);
        OZ.transferOwnershipDiamond(alice);

        //Post-conditions
        assertTrue(OZ.ownerDiamond() == owner);
        assertTrue(OZ.pendingOwner() == alice);
    }

}