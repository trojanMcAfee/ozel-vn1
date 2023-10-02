// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20} from "../../lib/forge-std/src/interfaces/IERC20.sol";

import "forge-std/console.sol";


contract ROImodule {

    function useUnderlying(uint amount_, address underlying_, address owner_) external {

        uint erc20Balance = IERC20(underlying_).balanceOf(address(this));

        //convert USDC to ETH/WETH - uniswap
        //convert ETH/WETH to rETH - rocketPool

    }

}