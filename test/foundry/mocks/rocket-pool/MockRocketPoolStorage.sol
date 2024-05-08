// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {MockRocketVault} from "./MockRocketVault.sol";

contract MockRocketPoolStorage {

    address public vault;

    constructor() {
        vault = address(new MockRocketVault());
    }

    function getAddress(bytes32 key_) external view returns(address) {
        // address vault = address(new MockRocketVault());

        return key_ == keccak256(abi.encodePacked('contract.address', 'rocketVault')) ?
            vault : 
            vault;
    }


}
