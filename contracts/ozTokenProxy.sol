// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {ozBeaconProxy} from "./BeaconProxy.sol";

contract ozTokenProxy is ozBeaconProxy {

    constructor(
        address beacon_, 
        bytes memory data_
    ) ozBeaconProxy(beacon_, data_) {}


    function beacon() external view returns(address) {
        return _beacon();
    }

    function implementation() external view returns(address) {
        return _implementations()[0];
    }

    //this is deprecated. See the note in BeaconProxy.sol to use _upgradeBeaconToAndCall()
    //remove this since it's deprecated (https://docs.openzeppelin.com/contracts/5.x/api/proxy#beacon)
    function setBeacon(address beacon_, bytes memory data_) external { //put an onlyOwner here
        _setBeacon(beacon_, data_);
    }
}