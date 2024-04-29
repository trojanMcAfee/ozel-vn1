// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../Errors.sol";
import {Modifiers} from "../Modifiers.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "forge-std/console.sol";

// import { IERC173 } from "../interfaces/IERC173.sol";

// contract OwnershipFacet is IERC173 {
//     function transferOwnership(address _newOwner) external override {
//         LibDiamond.enforceIsContractOwner();
//         LibDiamond.setContractOwner(_newOwner);
//     }

//     function owner() external override view returns (address owner_) {
//         owner_ = LibDiamond.contractOwner();
//     }
// }

contract OwnershipFacet is Modifiers {

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function ownerDiamond() public view returns (address) {
        return LibDiamond.contractOwner();
    }

    function pendingOwner() public view returns(address) {
        return s.pendingOwner;
    }

    function transferOwnershipDiamond(address newOwner_) external onlyOwner {
        s.pendingOwner = newOwner_;
        emit OwnershipTransferStarted(ownerDiamond(), newOwner_);
    }

    function acceptOwnership() external {
        if (pendingOwner() != msg.sender) revert OZError36(msg.sender);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner_) internal {
        delete s.pendingOwner;
        LibDiamond.setContractOwner(newOwner_);
        emit OwnershipTransferred(ownerDiamond(), newOwner_);
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    //Changes the implementations for ozTokens and/or wozTokens
    function changeOzTokenImplementations(address[] memory newImplementations_) external onlyOwner {
        bytes memory data = abi.encodeWithSignature('upgradeToBeacons(address[])', newImplementations_);
        Address.functionDelegateCall(address(this), data);
    }

}
