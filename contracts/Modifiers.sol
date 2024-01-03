// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IOZLrewards} from "./interfaces/IOZLrewards.sol";
import {AppStorage} from "./AppStorage.sol";

import "forge-std/console.sol";

contract Modifiers is IOZLrewards {

    AppStorage internal s;

    modifier updateReward(address user_) {
        s.r.rewardPerTokenStored = rewardPerToken();
        s.r.updatedAt = lastTimeRewardApplicable();

        if (user_ != address(0)) {
            s.r.rewards[user_] = earned(user_);
            s.r.userRewardPerTokenPaid[user_] = s.r.rewardPerTokenStored;
        }

        _;
    }



}