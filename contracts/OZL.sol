// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";

import "forge-std/console.sol";


contract OZL is ERC20Upgradeable {

    constructor() {
        _disableInitializers();
    }


    function initialize(
        string memory name_, 
        string memory symbol_
    ) external initializer {
        __ERC20_init(name_, symbol_);
    }


    function getRewards() public view {
        console.log('hellooo');
    }


}