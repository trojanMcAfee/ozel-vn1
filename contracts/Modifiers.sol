// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IOZLrewards} from "./interfaces/IOZLrewards.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {AppStorage, OZLrewards} from "./AppStorage.sol";
import "./Errors.sol";

import "forge-std/console.sol";

contract Modifiers is IOZLrewards {

    AppStorage internal s; 

    modifier updateReward(address user_, address ozDiamond_) {
        // OZLrewards memory r = ozIDiamond(ozDiamond_).getRewardsData();

        // if (ozDiamond_ == address(0)) {
        //     r = s.r;
        // }
        //--------

        // OZLrewards memory r = 
        //     ozDiamond_ == address(0) ? s.r : ozIDiamond(ozDiamond_).getRewardsData();

        // r.rewardPerTokenStored = rewardPerToken();
        // r.updatedAt = lastTimeRewardApplicable();

        // if (user_ != address(0)) {
        //     r.rewards[user_] = earned(user_);
        //     r.userRewardPerTokenPaid[user_] = r.rewardPerTokenStored;
        // }
        //------

        if (user_ != address(0)) {
            ozIDiamond(ozDiamond_).setRewardDataExternally(user_);
        } else { 
            s.r.rewardPerTokenStored = rewardPerToken();
            s.r.updatedAt = lastTimeRewardApplicable();
        }

        _;
    }

    modifier onlyRecipient {
        if (msg.sender != s.adminFeeRecipient) revert OZError13(msg.sender);
        _;
    }

    modifier onlyOzToken { 
        if (!s.ozTokenRegistryMap[msg.sender]) revert OZError13(msg.sender);
        _;
    }

}


