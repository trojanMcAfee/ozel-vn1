// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IOZLrewards} from "./interfaces/IOZLrewards.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {AppStorage, OzTokens} from "./AppStorage.sol";
import {Helpers} from "./libraries/Helpers.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./Errors.sol";

import "forge-std/console.sol";

contract Modifiers is IOZLrewards {

    using Helpers for address[];
    using BitMaps for BitMaps.BitMap;

    AppStorage internal s;
    

    modifier updateReward(address user_, address ozDiamond_) {
        if (ozDiamond_ != address(0)) {
            ozIDiamond(ozDiamond_).setRewardsDataExternally(user_);
        } else {
            s.r.rewardPerTokenStored = rewardPerToken();
            s.r.updatedAt = lastTimeRewardApplicable();

            if (user_ != address(0)) {
                s.r.rewards[user_] = earned(user_);
                s.r.userRewardPerTokenPaid[user_] = s.r.rewardPerTokenStored;
            }
        }

        _;
    }

    modifier onlyRecipient {
        if (msg.sender != s.adminFeeRecipient) revert OZError13(msg.sender);
        _;
    }

    modifier onlyOzToken { 
        uint length = s.ozTokenRegistry.length;
        bool flag;

        //i think this code could be refactored
        for (uint i=0; i<length; i++) {
            if (s.ozTokenRegistry[i].ozToken == msg.sender) {
                flag = true;
            }
        }

        if (flag) {
            _;
        } else {
            revert OZError13(msg.sender);
        }
    }

    // modifier isPaused() {
    //     if (s.pauseMap.get(0)) {
    //         for (uint i=0; i < s.pauseIndexes - 1; i++) {
    //             if (s.pauseMap.get(i + 1)) {
    //                 revert OZError27(i + 1);
    //             }
    //         }
    //     }
    //     _;
    // }

    function _isPaused(address facet_) internal {
        if (s.pauseMap.get(0)) {
            uint index = s.facetToIndex[facet_];

            if (s.pauseMap.get(index)) 

            for (uint i=0; i < s.pauseIndexes - 1; i++) {
                if (s.pauseMap.get(i + 1)) {
                    revert OZError27(i + 1);
                }
            }
        }
    }

}



