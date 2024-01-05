// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


//needs to be an abstract contracts, instead of interface, so function sigs can be shared
abstract contract IOZLrewards {
    function setRewardsDuration(uint duration_) external virtual {}
    function notifyRewardAmount(uint amount_) external virtual {}
    function lastTimeRewardApplicable() public view virtual returns(uint) {}
    function rewardPerToken() public view virtual returns(uint) {}
    function earned(address user_) public view virtual returns(uint) {}
    function claimReward() external virtual {}
    function getRewardRate() external view virtual returns(uint) {}
    function getOZLCirculatingSupply() external view virtual returns(uint) {}
}