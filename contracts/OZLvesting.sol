// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";


contract OZLvesting is VestingWallet {

    address private immutable _OZL;


    constructor(
        address beneficiaryAddress_,
        uint64 startTimestamp_,
        uint64 durationSeconds_,
        address ozl_
    ) VestingWallet(beneficiaryAddress_, startTimestamp_, durationSeconds_) {
        _OZL = ozl_;
    }


    function released() public view override returns(uint) {
        return released(_OZL);
    }

    function releasable() public view override returns(uint) {
        return releasable(_OZL);
    }

    function release() public override {
        release(_OZL); //add the release tokens to circulating supply ***
    }

    function vestedAmount() public view returns(uint) {
        return vestedAmount(_OZL, uint64(block.timestamp));
    }


}