// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;



contract IOZLrewards {
    function setRewardsDuration(uint duration_) external;
    function notifyRewardAmount(uint amount_) external;
    function lastTimeRewardApplicable() external view returns(uint);
    function rewardPerToken() external view returns(uint);
    function earned(address user_) external view returns(uint);
    function getReward() external;
}