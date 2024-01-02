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
    // uint public s.duration;
    // uint public s.finishAt; 
    // uint public s.updatedAt; 
    // uint public s.rewardRate;
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
    function setRewardsDuration(uint duration_) external {
        LibDiamond.enforceIsContractOwner();
        require(s.finishAt < block.timestamp, 'rewards duration not finished');
        s.duration = duration_;
    }

    //Calculates the reward rate
    function notifyRewardAmount(uint amount_) external updateReward(address(0)) { //4:55
        LibDiamond.enforceIsContractOwner();

        if (block.timestamp > s.finishAt) {
            s.rewardRate = amount_ / s.duration;            
        } else {
            uint remainingRewards = s.rewardRate * (s.finishAt - block.timestamp);
            s.rewardRate = (remainingRewards + amount_) / s.duration;
        }

        require(s.rewardRate > 0, "reward rate = 0");
        require(
            s.rewardRate * s.duration <= s.ozlProxy.balanceOf(address(this)),
            'reward amount > balance'
        );

        s.finishAt = block.timestamp + s.duration;
        s.updatedAt = block.timestamp;
    }

    // function stake(uint amount_) external {}
    // function withdraw(uint amount_) external {}

    function lastTimeRewardApplicable() public view returns(uint) {
        return _min(block.timestamp, s.finishAt);
    }

    //Computes the amount of reward per ozToken created
    function rewardPerToken() public view returns(uint) {
        if (s.ozTokensArr[0].totalSupply == 0) return s.rewardPerTokenStored;

        return s.rewardPerTokenStored + (s.rewardRate * 
            (lastTimeRewardApplicable() - s.updateAt) * 1e18
        ) / s.ozTokensArr[0].totalSupply();
    }

    //Computes the rewards earned by an user
    function earned(address user_) public view returns(uint) {
        return (s.ozTokensArr[0].balanceOf(user_) * 
            (rewardPerToken() - s.userRewardPerTokenPaid[user_])) / 1e18
         + s.rewards[user_];
    }
    
    function getReward() external updateReward(msg.sender) { //add a reentrancy check
        uint reward = s.rewards[msg.sender];
        if (reward > 0) {
            s.rewards[msg.sender] = 0;
            s.ozlProxy.transfer(msg.sender, reward);
        }
    }


    //------
    //put this impl inside lastTimeRewardApplicable() ****
    function _min(uint x, uint y) private pure returns(uint) {
        return x <= y ? x : y;
    }


}