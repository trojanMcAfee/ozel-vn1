// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";



contract OZLvesting is VestingWallet {

    address private immutable _OZL;
    address private immutable _ozDiamond; 


    constructor(
        address beneficiaryAddress_,
        uint64 startTimestamp_,
        uint64 durationSeconds_,
        address ozl_,
        address diamond_
    ) VestingWallet(beneficiaryAddress_, startTimestamp_, durationSeconds_) {
        _OZL = ozl_;
        _ozDiamond = diamond_;
    }


    function released() public view override returns(uint) {
        return released(_OZL);
    }

    function releasable() public view override returns(uint) {
        return releasable(_OZL);
    }

    //test this with an active campaing
    function release() public override {
        uint amount = releasable(_OZL);
        release(_OZL); 
        ozIDiamond(_ozDiamond).addToCirculatingSupply(amount);
    }

    function vestedAmount() public view returns(uint) {
        return vestedAmount(_OZL, uint64(block.timestamp));
    }


}