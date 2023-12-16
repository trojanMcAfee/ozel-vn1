// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Asset} from "../../contracts/AppStorage.sol";
import {TestMethods} from "./TestMethods.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {Type} from "./AppStorageTests.sol";

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


    function test_inflation_attack() public {
        _dealUnderlying(Quantity.BIG);
        uint amountIn = 1000000;

        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        uint balAlice = ozERC20.balanceOf(alice);

        console.log('sharesAlice: ', sharesAlice);
        console.log('balAlice: ', balAlice);

        //--------
        console.log('--- begin attack ---');
        amountIn = 10_000e18 - 1;

        _createAndMintOzTokens(
            address(ozERC20), amountIn, alice, ALICE_PK, false, true, Type.IN
        );
        console.log('--- attack finished ---');
        //--------

        amountIn = 19999e18;
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        );

        uint balVictim = ozERC20.balanceOf(charlie);
        
        console.log('balVictim: ', balVictim);
        console.log('shares victim: ', sharesCharlie);

        

    }


}