// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


//Mocks the underlying stablecoin, either 6 decimals like USDC or 18 decimals like DAI
contract MockUnderlying {

    uint public decimals;
    uint public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public PERMIT_TYPEHASH;

    constructor(uint dec_) {
        decimals = dec_;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return spender != address(0) && amount > 0;
    }
}