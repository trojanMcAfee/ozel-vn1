// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IDiamondCut} from "../../contracts/interfaces/IDiamondCut.sol";

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

    function test_diamondCut() public {
        // struct FacetCut {
        //     address facetAddress;
        //     FacetCutAction action;
        //     bytes4[] functionSelectors;
        // }

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);

        vm.prank(owner);
        OZ.diamondCut(cuts, address(0), new bytes(0));



    }


}