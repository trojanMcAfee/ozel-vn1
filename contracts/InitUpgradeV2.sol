// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {AppStorage} from "./AppStorage.sol";

// import "hardhat/console.sol";
import "forge-std/console.sol";


contract InitUpgradeV2 {

    AppStorage internal s; 

    function init(
        address[] memory registry_,
        address diamond_
    ) external {

        uint length = registry_.length;
        for (uint i=0; i < length; i++) {
            s.ozTokenRegistry.push(registry_[i]);
        }

        s.ozDiamond = diamond_;
    }


}