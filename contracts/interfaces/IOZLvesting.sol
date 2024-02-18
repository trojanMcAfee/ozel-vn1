// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


interface IOZLvesting {

    function released() external view returns(uint);
    function releasable() external view returns(uint);
    function release() external;
    function vestedAmount() external view returns(uint);

    function beneficiary() external view returns (address);
    function start() external view returns (uint256);
    function duration() external view returns (uint256);
    function vestedAmount(uint64 timestamp) external view returns (uint256);
}