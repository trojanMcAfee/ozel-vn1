// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AppStorage} from "../AppStorage.sol";
import "../Errors.sol";


/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract ozBeacon {
    // address[] private _implementations;
    AppStorage private s;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address[] indexed implementations);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    // constructor(address[] memory implementations_) {
    //     _setImplementation(implementations_);
    // }

    /**
     * @dev Returns the current implementation address.
     */
    function getOzImplementations() public view returns (address[] memory) {
        return s.ozImplementations;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeToBeacons(address[] memory newImplementations_) public {
        LibDiamond.enforceIsContractOwner();
        _setImplementation(newImplementations_);
        emit Upgraded(newImplementations_);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address[] memory newImplementations_) private {
        // require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        // _implementation = newImplementation;

        for (uint i=0; i < newImplementations_.length; i++) {
            if (!Address.isContract(newImplementations_[i])) revert OZError24();
            s.ozImplementations[i] = newImplementations_[i];
        }
    }
}
