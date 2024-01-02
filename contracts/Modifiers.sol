// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IOZLrewards} from "./interfaces/IOZLrewards.sol";
import {AppStorage} from "./AppStorage.sol";

contract Modifiers is IOZLrewards {

    AppStorage.ozlRewards internal s;

    modifier updateRewards(address user_) {
        s.rewardPerTokenStored = rewardPerToken();
        s.updatedAt = lastTimeRewardApplicable();

        if (user_ != address(0)) {
            s.rewards[user_] = earned(user_);
            s.userRewardPerTokenPaid[user_] = rewardPerTokenStored;
        }

        _;
    }



}