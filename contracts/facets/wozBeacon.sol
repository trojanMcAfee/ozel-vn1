// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

//This and ozBeacon have a Ownable.sol for changing the implementation.
//Unify these two somewhere
contract wozBeacon is UpgradeableBeacon {
    constructor(
        address wozTokenImpl_
    ) UpgradeableBeacon(wozTokenImpl_) {}
}

