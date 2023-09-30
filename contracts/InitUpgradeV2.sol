// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {AppStorage} from "./AppStorage.sol";


contract InitUpgradeV2 {

    AppStorage internal s; 

    function init(
        address[] memory registry_
    ) external {

        // for (uint i=0; i < registry_.length; i++) {
        //     s.ozTokenRegistry[registry_[i]] = true;
        // }

    }


}