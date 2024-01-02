// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;



abstract contract IOZLrewards {
    function setRewardsDuration(uint duration_) external;
    function notifyRewardAmount(uint amount_) external;
    function lastTimeRewardApplicable() public view returns(uint);
    function rewardPerToken() public view returns(uint);
    function earned(address user_) public view returns(uint);
    function getReward() external;
}