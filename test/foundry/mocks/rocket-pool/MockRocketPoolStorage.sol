// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {MockRocketVault} from "./MockRocketVault.sol";
import {MockSettingsDeposit} from "./MockSettingsDeposit.sol";

contract MockRocketPoolStorage {

    address public vault;
    address public settingsDeposit;

    constructor() {
        vault = address(new MockRocketVault());
        settingsDeposit = address(new MockSettingsDeposit());
    }

    function getAddress(bytes32 key_) external view returns(address toReturn) {
        if (key_ == keccak256(abi.encodePacked('contract.address', 'rocketVault'))) {
            toReturn = vault;
        } else if (key_ == keccak256(abi.encodePacked("contract.address", "rocketDAOProtocolSettingsDeposit"))) {
            toReturn = settingsDeposit;
        }
    }
}
