// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


interface IWETH {
    function deposit() external payable;
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function withdraw(uint256 amount) external;
}

