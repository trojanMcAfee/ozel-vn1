// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


interface IAave {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}