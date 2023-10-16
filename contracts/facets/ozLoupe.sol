// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {DiamondLoupeFacet} from "./DiamondLoupeFacet.sol";
import {AppStorage} from "../AppStorage.sol";


contract ozLoupe is DiamondLoupeFacet {

    AppStorage internal s;

    function getRewardMultiplier() external view returns(uint) {
        return s.rewardMultiplier;
    }


}