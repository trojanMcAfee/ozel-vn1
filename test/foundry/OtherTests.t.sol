// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Asset} from "../../contracts/AppStorage.sol";
import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";


contract OtherTests is TestMethods {

    function test_totalUnderlying() public {
        //Pre-condition + Action
        _minting_approve_smallMint();

        //Post-conditions
        uint totalUSD = OZ.totalUnderlying(Asset.USD);
        uint ROUNDER = 1e1;
        uint ozDiamondRethBalance = IERC20Permit(rEthAddr).balanceOf(address(OZ));

        assertTrue(totalUSD / ROUNDER == ((ozDiamondRethBalance * OZ.rETH_USD()) / 1 ether^2)/ ROUNDER);
    }


}