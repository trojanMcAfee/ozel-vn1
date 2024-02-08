// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {ozBeaconProxy} from "./ozBeaconProxy.sol";


contract wozTokenProxy is ozBeaconProxy {

    constructor(
        address ozDiamond_, 
        bytes memory data_,
        uint implIndex_
    ) ozBeaconProxy(ozDiamond_, data_, implIndex_) {}


    function beacon() external view returns(address) {
        return _beacon();
    }

    function implementation() external view returns(address) {
        return _implementation();
    }

    function _implementation() internal view override returns(address) {
        return _implementations()[1];
    }
}

//integrating the BeaconProxy, Proxy into the rest of the new woz architecture
//consider doing with tokenProxy contract and route through the implementations
//using another way when the different contracts get called.