// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {IOZLrewards} from "./interfaces/IOZLrewards.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {AppStorage, OzTokens} from "./AppStorage.sol";
import {Helpers} from "./libraries/Helpers.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import "./Errors.sol";

import "forge-std/console.sol";

contract Modifiers is IOZLrewards {

    using Helpers for address[];

    AppStorage internal s;
    

    /**
     * It updates the main variables that calculate the reward rate that
     * an user is going to accumulate.
     */
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

    modifier onlyOwner() {
        if (LibDiamond.contractOwner() != msg.sender) revert OZError33(msg.sender);
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

    modifier lock(bytes32 location_) {
        assembly {
            if tload(location_) {
                let data := mload(0x40)
                mstore(data, shl(224, 0xb9554255)) 

                mstore(0x40, add(data, 4))

                revert(data, 4)
            }
            tstore(location_, 1)
        }
        _;
        assembly {
            tstore(location_, 0)
        }
    }
}



