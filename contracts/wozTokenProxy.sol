// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";


contract wozTokenProxy is BeaconProxy {

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
}