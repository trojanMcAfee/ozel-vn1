// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


//Mocks the underlying stablecoin, either 6 decimals like USDC or 18 decimals like DAI
contract MockUnderlying {

    uint public decimals;

    constructor(uint dec_) {
        decimals = dec_;
    }


}