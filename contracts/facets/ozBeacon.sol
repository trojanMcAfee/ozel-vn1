// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";


contract ozBeacon is UpgradeableBeacon {
    constructor(
        address ozTokenImpl_
    ) UpgradeableBeacon(ozTokenImpl_) {}
}