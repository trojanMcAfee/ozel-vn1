// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../Errors.sol";
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

contract OwnershipFacet {
    // function transferOwnershipDiamond(address _newOwner) external {
    //     LibDiamond.enforceIsContractOwner();
        // LibDiamond.setContractOwner(_newOwner);
    // }

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function transferOwnershipDiamond(address newOwner_) external onlyOwner {
        s.pendingOwner = newOwner_;
        emit OwnershipTransferStarted(ownerDiamond(), newOwner_);
    }

    function acceptOwnership() external virtual {
        if (pendingOwner() != msg.sender) revert OZError36(msg.sender);
        _transferOwnership(sender);
    }

    function _transferOwnership(address newOwner_) internal {
        delete s.pendingOwner;
        LibDiamond.setContractOwner(newOwner_);
        emit OwnershipTransferred(ownerDiamond(), newOwner_);
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }


    function ownerDiamond() external view returns (address) {
        return LibDiamond.contractOwner();
    }

    function pendingOwner() external view returns(address) {
        return s.pendingOwner;
    }

}
