// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


contract OZL is ERC20Upgradeable {

    using FixedPointMathLib for uint;

    address constant rEthAddr = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    constructor() {
        _disableInitializers();
    }


    function initialize(
        string memory name_, 
        string memory symbol_
    ) external initializer {
        __ERC20_init(name_, symbol_);
    }



    function getBal() public view returns(uint) {
        uint bal = IERC20Permit(rEthAddr).balanceOf(address(this));
        console.log('rETH bal (from fees) ***: ', bal);

        return bal;
    }


    function getExchangeRate() public view returns(uint) {
        uint ONE = 1;
        uint totalFees = IERC20Permit(rEthAddr).balanceOf(address(this));
        uint ozlSupply = totalSupply();

        if (ozlSupply == 0) return ONE;

        return ONE.mulDivDown(totalFees, ozlSupply);
    }


}