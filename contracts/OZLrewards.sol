// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "./interfaces/IERC20Permit.sol";


contract OZLrewards {

    IERC20Permit public immutable ozStable; //stakingToken
    IERC20Permit public immutable OZL; //rewardsToken

    address public owner;

    uint public duration;
    uint public finishAt; 
    uint public updatedAt; 
    uint public rewardRate;
    uint public rewardPerTokenStored;

    mapping(
        address user => uint rewardPerTokenStoredPerUser
    ) public userRewardPerTokenPaid;
    mapping(address user => uint rewardsEarned) public rewards;

    uint public totalSupply = ozStable.totalSupply();
    // mapping(address=>uint) balanceOf; --> amount of staked token by user

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner" );
        _;
    }


    constructor(address stakingToken_, address rewardsToken_) {
        owner = msg.sender;
        ozStable = IERC20Permit(stakingToken_);
        OZL = IERC20Permit(rewardsToken_);
    }


    function setRewardsDuratino(uint duration_) external onlyOwner {
        require(finishAt < block.timestamp, 'rewards duration not finished');
        duration = duration_;
    }

    function notifyRewardAmount(uint amount_) external onlyOwner { //4:55
        if (block.timestamp > finishAt) {
            rewardRate = amount_ / duration;            
        } else {
            uint remainingRewards = rewardRate * (finishAt - block.timestamp);
            rewardRate = (remainingRewards + amount_) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= OZL.balanceOf(address(this)),
            'reward amount > balance'
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }
    // function stake(uint amount_) external {}
    // function withdraw(uint amount_) external {}
    function earned(address user_) external view returns(uint) {}
    function getReward() external {}


}