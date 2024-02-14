// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "../interfaces/IERC20Permit.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {Modifiers} from "../Modifiers.sol";
import {IOZL} from "../interfaces/IOZL.sol";
import "../Errors.sol";

import "forge-std/console.sol";


contract OZLrewards is Modifiers { //check if I can put IOZLrewards here instead of Modifiers

    //Sets the lenght of the reward campaign
    function setRewardsDuration(uint duration_) public override {
        LibDiamond.enforceIsContractOwner();
        if (s.r.finishAt >= block.timestamp) revert OZError15();
        s.r.duration = duration_;
    }

    
    //Calculates the reward rate
    function notifyRewardAmount(uint amount_) public override updateReward(address(0), address(0)) { //4:55
        LibDiamond.enforceIsContractOwner();

        if (block.timestamp > s.r.finishAt) {
            s.r.rewardRate = amount_ / s.r.duration;    
        } else {
            uint remainingRewards = s.r.rewardRate * (s.r.finishAt - block.timestamp);
            s.r.rewardRate = (remainingRewards + amount_) / s.r.duration;
        }

        if (s.r.rewardRate <= 0) revert OZError16();
        if (
            s.r.rewardRate * s.r.duration > IOZL(s.ozlProxy).balanceOf(address(this))
        ) revert OZError17();

        s.r.finishAt = block.timestamp + s.r.duration;
        s.r.updatedAt = block.timestamp;
    }


    function lastTimeRewardApplicable() public view override returns(uint) {
        return Helpers.min(block.timestamp, s.r.finishAt);
    }

    //Computes the amount of reward per ozToken created
    function rewardPerToken() public view override returns(uint) {
        uint totalSupply = _getOzTokensTotalSupply();

        if (totalSupply == 0) return s.r.rewardPerTokenStored;

        return s.r.rewardPerTokenStored + (s.r.rewardRate * 
            (lastTimeRewardApplicable() - s.r.updatedAt) * 1e18
        ) / totalSupply;
    }


    //Computes the rewards earned by an user
    function earned(address user_) public view override returns(uint) {
        return (_getUserTotalOzTokens(user_) * 
            (rewardPerToken() - s.r.userRewardPerTokenPaid[user_])) / 1e18
         + s.r.rewards[user_];
    }
    
    function claimReward() external override updateReward(msg.sender, address(0)) returns(uint) { //add a reentrancy check
        uint reward = s.r.rewards[msg.sender];
        
        if (reward > 0) {
            s.r.rewards[msg.sender] = 0;
            IOZL(s.ozlProxy).transfer(msg.sender, reward); 
            s.r.circulatingSupply += reward;
        }

        return reward;
    }


    function getRewardsData() external view override returns(
        uint rewardRate,
        uint circulatingSupply,
        uint pendingAllocation,
        uint recicledSupply,
        int durationLeft
    ) {
        return (
            s.r.rewardRate,
            s.r.circulatingSupply,
            IOZL(s.ozlProxy).balanceOf(address(this)) - s.r.recicledSupply,
            s.r.recicledSupply,
            int(s.r.finishAt) - int(block.timestamp)  
        );
    }

    function modifySupply(uint ozlAmount_) external { //put an onlyOZL modifier here
        s.r.circulatingSupply -= ozlAmount_;
        s.r.recicledSupply += ozlAmount_;
    }

    function setRewardsDataExternally(address user_) external { //put an onlySender modifier
        s.r.rewardPerTokenStored = rewardPerToken();
        s.r.updatedAt = lastTimeRewardApplicable();
        s.r.rewards[user_] = earned(user_);
        s.r.userRewardPerTokenPaid[user_] = s.r.rewardPerTokenStored;
    }

    
    function startNewReciclingCampaign(uint duration_) external { //put an onlyOnwer
        setRewardsDuration(duration_);
        notifyRewardAmount(s.r.recicledSupply);
        s.r.recicledSupply = 0;
    }


    //-----
    function _getUserTotalOzTokens(address user_) private view returns(uint total) {    
        uint length = s.ozTokenRegistry.length;
        
        for (uint8 i=0; i < length; i++) {
            total += IERC20Permit(s.ozTokenRegistry[i].ozToken).balanceOf(user_);
        }
    }

    function _getOzTokensTotalSupply() private view returns(uint total) {
        uint length = s.ozTokenRegistry.length;

        for (uint8 i=0 ; i < length; i++) {
            total += IERC20Permit(s.ozTokenRegistry[i].ozToken).totalSupply();
        }
    }
}


//add events here **** https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol