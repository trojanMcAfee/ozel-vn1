// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


contract MockRethWethPoolBalancer {
    function getPausedState() external pure returns(bool, uint, uint){
        return (false, 0, 0);
    }

    function getPoolId() external pure returns(bytes32) {
        return bytes32(0);
    }
}