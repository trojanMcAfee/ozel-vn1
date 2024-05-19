// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {Helpers} from "./../../../../contracts/libraries/Helpers.sol";
import {ozIToken} from "./../../../../contracts/interfaces/ozIToken.sol";

import {console} from "forge-std/console.sol";


contract MockRocketVault {

    using Helpers for *;
    
    bool flag;

    function balanceOf(string memory pool_) external view returns(uint) {
        return !flag ? pool_.compareStrings('rocketDepositPool') ? 1 : 0 : 0;
    }
}


contract MockReentrantRocketVault {

    address deadAddr = 0x000000000000000000000000000000000000dEaD;

    address immutable ozERC20addr;

    constructor(ozIToken ozToken_) {
        ozERC20addr = address(ozToken_);
    }

    function balanceOf(string memory pool_) external {
        bytes memory data = abi.encode(pool_);
        console.log('ozERC20: ', ozERC20addr);
        ozIToken(ozERC20addr).mint(data, deadAddr);
    }
}   