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
        uint totalrETH = OZ.totalUnderlying(Asset.UNDERLYING);
        uint totalUSD = OZ.totalUnderlying(Asset.USD);
        uint rEthEth = OZ.rETH_ETH();
        uint ethUsd = OZ.ETH_USD();

        uint ozDiamondRethBalance = IERC20Permit(rEthAddr).balanceOf(address(OZ));

        console.log('ozDiamondRethBalance: ', ozDiamondRethBalance);
        console.log('totalUSD: ', totalUSD);
        console.log('rETH_USD: ', OZ.rETH_USD());
        console.log('sum: ', (ozDiamondRethBalance * OZ.rETH_USD()) / 1 ether^2);

        assertTrue(totalUSD / 1e2 == ((ozDiamondRethBalance * OZ.rETH_USD()) / 1 ether^2)/ 1e2);


    }


}