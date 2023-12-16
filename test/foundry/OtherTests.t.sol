// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Asset} from "../../contracts/AppStorage.sol";
import {TestMethods} from "./TestMethods.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {Type} from "./AppStorageTests.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {AmountsIn} from "../../contracts/AppStorage.sol";

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
        address attacker = alice;
        address victim = charlie;
        uint amountIn = 1;

        console.log(11);
        // vm.expectRevert();
        // (ozIToken ozERC20,) = _createAndMintOzTokens(
        //     testToken, amountIn, attacker, ALICE_PK, true, false, Type.IN
        // );

        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));
        
        (bytes memory data) = _createDataOffchain(
            ozERC20, amountIn, ALICE_PK, attacker, Type.IN
        );

        (uint[] memory minAmountsOut,,,) = HelpersLib.extract(data);

        vm.startPrank(attacker);

        IERC20Permit(testToken).approve(address(ozDiamond), amountIn);

        AmountsIn memory amounts = AmountsIn(
            amountIn,
            minAmountsOut[0],
            minAmountsOut[1]
        );

        bytes memory mintData = abi.encode(amounts, attacker);
        vm.expectRevert();
        ozERC20.mint(mintData); 

        console.log(12);

        uint balAlice = ozERC20.balanceOf(alice);

        // console.log('sharesAlice: ', sharesAlice);
        console.log('balAlice: ', balAlice);

        //--------
        console.log('--- begin attack ---');
        amountIn = 10_000e18 - 1;

        _createAndMintOzTokens(
            address(ozERC20), amountIn, attacker, ALICE_PK, false, true, Type.IN
        );
        console.log('--- attack finished ---');
        //--------

        amountIn = 19999e18;
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        );

        uint balVictim = ozERC20.balanceOf(victim);
        // assertTrue(balVictim <= 1);
        
        console.log('balVictim: ', balVictim);
        console.log('shares victim: ', sharesCharlie);

        

    }


}