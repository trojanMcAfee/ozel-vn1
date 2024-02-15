// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";


contract OZLproxy is TransparentUpgradeableProxy {

    ozIDiamond private immutable OZ;

    constructor(
        address logic_,
        address admin_,
        bytes memory data_,
        address ozDiamond_
    ) TransparentUpgradeableProxy(logic_, admin_, data_) {
        OZ = ozIDiamond(ozDiamond_);
    }

    
    function _fallback() internal override {
        OZ.isPaused(address(this));
        super._fallback();
    }
}