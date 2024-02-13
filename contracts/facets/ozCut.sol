// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {DiamondCutFacet} from "./DiamondCutFacet.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Modifiers} from "../Modifiers.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../Errors.sol";

import "forge-std/console.sol";


contract ozCut is Modifiers, DiamondCutFacet {

    using BitMaps for BitMaps.BitMap;

    function changeDefaultSlippage(uint16 newBps_) external {
        LibDiamond.enforceIsContractOwner();
        s.defaultSlippage = newBps_;
    }

    function changeUniFee(uint24 newBps_) external {
        LibDiamond.enforceIsContractOwner();
        s.uniFee = newBps_;
    }

    function storeOZL(address ozlProxy_) external { //make this func a one time thing
        LibDiamond.enforceIsContractOwner();
        s.ozlProxy = ozlProxy_;
    }

    function changeAdminFeeRecipient(address newRecipient_) external onlyRecipient {
        s.adminFeeRecipient = newRecipient_;
    }

    function changeProtocolFee(uint24 newFee_) external {
        LibDiamond.enforceIsContractOwner();
        s.protocolFee = newFee_;
    }

    function changeAdminFee(uint16 newFee_) external {
        LibDiamond.enforceIsContractOwner();
        s.adminFee = newFee_;
    }

    //Pauses a part or the whole system.
    //Returns true if at least one part of the system is paused.
    //Returns paused if nothing is paused.
    function pause(uint index_, bool newState_) external returns(bool) {
        LibDiamond.enforceIsContractOwner();
        if (s.pauseMap.get(index_) == newState_) revert OZError28(newState_);
        if (index_ == 1) revert OZError29();
        
        s.pauseMap.setTo(index_, newState_);

        //Refactor this (if possible)
        for (uint i=1; i < s.pauseIndexes; i++) {
            if (s.pauseMap.get(i)) {
                s.pauseMap.setTo(1, true);
                return true;
            }
        }

        return false;
    }
}