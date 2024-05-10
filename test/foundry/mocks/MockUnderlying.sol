// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {console} from "forge-std/console.sol";


//Mocks the underlying stablecoin, either 6 decimals like USDC or 18 decimals like DAI
contract MockUnderlying {

    uint public decimals;
    uint public nonces;
    uint public totalSupply;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public PERMIT_TYPEHASH;

    address public foundry = 0x34A1D3fff3958843C43aD80F30b94c510645C316;
    address public alice = 0x37cB1a23e763D2F975bFf3B2B86cFa901f7B517E;

    constructor(uint dec_) {
        decimals = dec_;
        totalSupply = 100_000_000 * 10 ** dec_;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return spender != address(0) && amount > 0;
    }

    function balanceOf(address user) external returns(uint) {
        return user == alice && msg.sender == foundry ? 1: 0;
    }
}