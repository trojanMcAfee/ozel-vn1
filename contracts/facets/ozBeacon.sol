// SPDX-License-Identifier: MIT
// Modified version - OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity 0.8.21;

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// import {Helpers} from "../libraries/Helpers.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract ozBeacon is IBeacon, Ownable {
    // address[] private _implementations;

    enum ImplType {
        STABLE,
        NON_STABLE
    }

    mapping(ImplType typeImpl => address impl) private _implementations;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _addImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation(ImplType type_) public view virtual override returns (address) {
        require(_implementations[type_] == address(0), "impl does not exist");
        return _implementations[type_];
    }

    //put the beacon as a facet of ozDiamond ******

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
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _addImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _addImplementation(ImplType type_, address newImplementation_) private {
        require(Address.isContract(newImplementation_), "UpgradeableBeacon: implementation is not a contract");
        _implementations[type_] = newImplementation_;
    }
}
