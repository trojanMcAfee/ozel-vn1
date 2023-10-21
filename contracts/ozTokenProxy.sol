// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";


contract ozTokenProxy is BeaconProxy {

    constructor(
        address beacon_, 
        bytes memory data_
    ) BeaconProxy(beacon_, data_) {}


    function beacon() external view returns(address) {
        return _beacon();
    }

    function implementation() external view returns(address) {
        return _implementation();
    }

    function setBeacon(address beacon_, bytes memory data_) external { //put an onlyOwner here
        _setBeacon(beacon_, data_);
    }
}