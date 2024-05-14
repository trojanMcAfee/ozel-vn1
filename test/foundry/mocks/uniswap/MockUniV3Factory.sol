// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {console} from "forge-std/console.sol";

contract MockUniV3Factory {

    address rETH;
    address WETH;
    address rETHwETHpool;

    constructor(address rEthAddr_, address wethAddr_, address rethWethPool_) {
        rETH = rEthAddr_;
        WETH = wethAddr_;
        rETHwETHpool = rethWethPool_;
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool) {
        if (tokenA == rETH && tokenB == WETH && fee != 0) return rETHwETHpool;
        return address(1);
    }

}