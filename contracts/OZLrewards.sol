// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {Modifiers} from "./Modifiers.sol";


contract OZLrewards is Modifiers {

    // IERC20Permit public immutable ozToken; //stakingToken
    // IERC20Permit public immutable OZL; //rewardsToken

    // address public owner;

    //--------------
    // uint public duration;
    // uint public finishAt; 
    // uint public updatedAt; 
    // uint public rewardRate;
    // uint public rewardPerTokenStored;

    // mapping(
    //     address user => uint rewardPerTokenStoredPerUser
    // ) public userRewardPerTokenPaid;
    // mapping(address user => uint rewardsEarned) public rewards;
    //-----------

    // uint public totalSupply = ozToken.totalSupply();
    // mapping(address=>uint) balanceOf; --> amount of staked token by user

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "not owner" );
    //     _;
    // }


    // constructor(address rewardsToken_) {
    //     // owner = msg.sender;
    //     // ozToken = IERC20Permit(stakingToken_);
    //     OZL = IERC20Permit(rewardsToken_);
    // }

    //Sets the lenght of the reward campaign
    function setRewardsDuration(uint duration_) external override {
        LibDiamond.enforceIsContractOwner();
        require(s.r.finishAt < block.timestamp, 'rewards duration not finished');
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

        require(s.r.rewardRate > 0, "reward rate = 0");
        require(
            s.r.rewardRate * s.r.duration <= IERC20Permit(s.ozlProxy).balanceOf(address(this)),
            'reward amount > balance'
        );

        s.r.finishAt = block.timestamp + s.r.duration;
        s.r.updatedAt = block.timestamp;
    }

    // function stake(uint amount_) external {}
    // function withdraw(uint amount_) external {}

    function lastTimeRewardApplicable() public view override returns(uint) {
        return _min(block.timestamp, s.r.finishAt);
    }

    //Computes the amount of reward per ozToken created
    function rewardPerToken() public view override returns(uint) {
        uint totalSupply = IERC20Permit(s.ozTokensArr[0]).totalSupply();

        if (totalSupply == 0) return s.r.rewardPerTokenStored;

        return s.r.rewardPerTokenStored + (s.r.rewardRate * 
            (lastTimeRewardApplicable() - s.r.updatedAt) * 1e18
        ) / totalSupply;
    }

    //Computes the rewards earned by an user
    function earned(address user_) public view override returns(uint) {
        return (IERC20Permit(s.ozTokensArr[0]).balanceOf(user_) * 
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


    //------
    //put this impl inside lastTimeRewardApplicable() ****
    function _min(uint x, uint y) private pure returns(uint) {
        return x <= y ? x : y;
    }


}