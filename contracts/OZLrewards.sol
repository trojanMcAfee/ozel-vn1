// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {Helpers} from "./libraries/Helpers.sol";
import {Modifiers} from "./Modifiers.sol";
import {IOZL} from "./interfaces/IOZL.sol";
import "./Errors.sol";

import "forge-std/console.sol";


contract OZLrewards is Modifiers {

    //Sets the lenght of the reward campaign
    function setRewardsDuration(uint duration_) external override {
        LibDiamond.enforceIsContractOwner();
        if (s.r.finishAt >= block.timestamp) revert OZError15();
        s.r.duration = duration_;
    }

    //Calculates the reward rate
    function notifyRewardAmount(uint amount_) external override updateReward(address(0)) { //4:55
        LibDiamond.enforceIsContractOwner();

        if (block.timestamp > s.r.finishAt) {
            s.r.rewardRate = amount_ / s.r.duration;    
        } else {
            uint remainingRewards = s.r.rewardRate * (s.r.finishAt - block.timestamp);
            s.r.rewardRate = (remainingRewards + amount_) / s.r.duration;
        }

        if (s.r.rewardRate <= 0) revert OZError16();
        if (
            s.r.rewardRate * s.r.duration > IERC20Permit(s.ozlProxy).balanceOf(address(this))
        ) revert OZError17();

        s.r.finishAt = block.timestamp + s.r.duration;
        s.r.updatedAt = block.timestamp;
    }


    function lastTimeRewardApplicable() public view override returns(uint) {
        return Helpers.min(block.timestamp, s.r.finishAt);
    }

    //Computes the amount of reward per ozToken created
    function rewardPerToken() public view override returns(uint) {
        uint totalSupply = IERC20Permit(s.ozTokenRegistry[0]).totalSupply();

        if (totalSupply == 0) return s.r.rewardPerTokenStored;

        return s.r.rewardPerTokenStored + (s.r.rewardRate * 
            (lastTimeRewardApplicable() - s.r.updatedAt) * 1e18
        ) / totalSupply;
    }

    //Computes the rewards earned by an user
    function earned(address user_) public view override returns(uint) {
        return (IERC20Permit(s.ozTokenRegistry[0]).balanceOf(user_) * 
            (rewardPerToken() - s.r.userRewardPerTokenPaid[user_])) / 1e18
         + s.r.rewards[user_];
    }
    
    function getReward() external override updateReward(msg.sender) { //add a reentrancy check
        uint reward = s.r.rewards[msg.sender];
        if (reward > 0) {
            s.r.rewards[msg.sender] = 0;
            IERC20Permit(s.ozlProxy).transfer(msg.sender, reward);
        }
    }

    function getRewardRate() external view override returns(uint) {
        return s.r.rewardRate;
    }


}