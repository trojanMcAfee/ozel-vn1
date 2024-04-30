// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../Errors.sol";
import {Modifiers} from "../Modifiers.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "forge-std/console.sol";

// import { IERC173 } from "../interfaces/IERC173.sol";

// contract OwnershipFacet is IERC173 {


//All owner/admin ownership transfer methods are here except for OZLadmin
contract OwnershipFacet is Modifiers {

    using Address for address;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function ownerDiamond() public view returns (address) {
        return LibDiamond.contractOwner();
    }

    function ownerOZL() public view returns(address) {
        bytes memory data = abi.encodeWithSignature('getOZLadmin()');
        data = address(this).functionStaticCall(data);
        return abi.decode(data, (address));
    }

    function pendingOwnerOZL() public view returns(address) {
        return s.pendingOwnerOZL;
    }

    // function transferOwnershipOZL(address newOwner_) external onlyOwnerOZL {

    // }

    function pendingOwnerDiamond() public view returns(address) {
        return s.pendingOwnerDiamond;
    }

    function transferOwnershipDiamond(address newOwner_) external onlyOwner {
        s.pendingOwnerDiamond = newOwner_;
        emit OwnershipTransferStarted(ownerDiamond(), newOwner_);
    }

    function acceptOwnership() external {
        if (pendingOwnerDiamond() != msg.sender) revert OZError36(msg.sender);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner_) internal {
        delete s.pendingOwnerDiamond;
        LibDiamond.setContractOwner(newOwner_);
        emit OwnershipTransferred(ownerDiamond(), newOwner_);
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    //Changes the implementations for ozTokens and/or wozTokens
    function changeOzTokenImplementations(address[] memory newImplementations_) external onlyOwner {
        bytes memory data = abi.encodeWithSignature('upgradeToBeacons(address[])', newImplementations_);
        address(this).functionDelegateCall(data);
    }

    // function transferAllOwnerships() {} //finish this and put a 2step on changeOZLadmin() ^

}
