// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../base/TestMethods.sol";
import {OZError33} from "../../../contracts/Errors.sol";



contract ozCutTest is TestMethods {

    //Tests that the protocol fee can be modified successfully
    function test_change_protocol_fee() public {
        //Pre-conditions
        uint oldFee = OZ.getProtocolFee();
        uint24 newFee = 2;

        //Action
        vm.prank(owner);
        OZ.changeProtocolFee(newFee);

        //Post-conditions
        assertTrue(oldFee != newFee);
        assertTrue(newFee == OZ.getProtocolFee());
    }

    //Tests taht only the owner can change the admin fee
    function test_change_admin_fee() public {
        //Pre-conditions
        uint oldFee = OZ.getAdminFee();
        uint16 newFee = 10;

        //Action
        vm.prank(owner);
        OZ.changeAdminFee(newFee);

        //Post-conditions
        assertTrue(oldFee != newFee);
        assertTrue(newFee == OZ.getAdminFee());
    }

    //Tests that it'll revert when a non-owner tries to change the admin fee
    function test_change_admin_fee_onlyOwner() public {
         //Pre-conditions
        
        uint16 newFee = 10;
        
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(OZError33.selector, alice)
        );
        OZ.changeAdminFee(newFee);
    }

    


}