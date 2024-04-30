// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IOZLrewards} from "./interfaces/IOZLrewards.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {AppStorage, OzTokens} from "./AppStorage.sol";
import {Helpers} from "./libraries/Helpers.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import "./Errors.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "forge-std/console.sol";


contract Modifiers is IOZLrewards {

    using Helpers for address[];
    using Address for address;

    AppStorage internal s;
    

    //check if ozDiamond_ is needed as a param or instead i can use address(this)
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

    modifier onlyOwner {
        if (LibDiamond.contractOwner() != msg.sender) revert OZError33(msg.sender);
        _;
    }

    modifier onlyOwnerOZL {
        //put this in a Lib, the same as ownerOZL() call
        bytes memory data = abi.encodeWithSignature('getOZLadmin()');
        data = address(this).functionCall(data);

        console.log('msg.sender: ', msg.sender);
        console.log('abi.decode(data, (address): ', abi.decode(data, (address)));

        if (msg.sender != abi.decode(data, (address))) revert OZError33(msg.sender);
        _;
    }

    modifier onlyPendingOZL {
        bytes memory data = abi.encodeWithSignature('pendingOwnerOZL()');
        data = address(this).functionDelegateCall(data);

        console.log(1);
        if (msg.sender != abi.decode(data, (address))) revert OZError33(msg.sender);
        console.log(2);
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
}



