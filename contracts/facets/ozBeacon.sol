// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity 0.8.24;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AppStorage} from "../AppStorage.sol";
import "../Errors.sol";

import "forge-std/console.sol";


/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
 //Modified all of this contract
contract ozBeacon {

    AppStorage private s;

    using Helpers for address[];

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address[] indexed implementations);

    /**
     * @dev Returns the current implementations:
     * index 0 - ozTokenProxy.
     * index 1 - wozTokenProxy.
     */
    function getOzImplementations() public view returns (address[] memory) {
        return s.ozImplementations;
    }

    /**
     * @dev Upgrades the beacon to new implementations.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementations` must be a contracts.
     */
    function upgradeToBeacons(address[] memory newImplementations_) public {
        LibDiamond.enforceIsContractOwner();
        _setImplementations(newImplementations_);
        emit Upgraded(newImplementations_);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementations(address[] memory newImplementations_) private {
        if (newImplementations_[0] == address(0) && newImplementations_[1] == address(0)) revert OZError32();

        newImplementations_.checkForContracts();

        if (newImplementations_[0] != address(0) && newImplementations_[1] != address(0)) {
            s.ozImplementations[0] = newImplementations_[0];
            s.ozImplementations[1] = newImplementations_[1];
        } else {
            newImplementations_[0] != address(0) ? 
                s.ozImplementations.replace(0, newImplementations_[0]) : 
                s.ozImplementations.replace(1, newImplementations_[1]);
        }
    }

    
}
