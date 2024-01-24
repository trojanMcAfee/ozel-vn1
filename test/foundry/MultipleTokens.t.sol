// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {TestMethods} from "./TestMethods.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


contract MultipleTokensTest is TestMethods {

    using FixedPointMathLib for uint;

    
    function test_multiple_ozToken_balances() public {
        //Pre-conditions
        ozIToken ozERC20_1 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20-1", "ozERC20_1"
        ));

        ozIToken ozERC20_2 = ozIToken(OZ.createOzToken(
            secondTestToken, "Ozel-ERC20-2", "ozERC20_2"
        ));
        

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountInFirst = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        uint amountInSecond = (rawAmount / 2) * 10 ** IERC20Permit(secondTestToken).decimals();

        _startCampaign();

        //Actions
        _mintOzTokens(ozERC20_1, alice, testToken, amountInFirst);
        _mintOzTokens(ozERC20_2, alice, secondTestToken, amountInSecond);
        _mintOzTokens(ozERC20_2, bob, secondTestToken, amountInSecond);
        _mintOzTokens(ozERC20_1, charlie, testToken, amountInFirst / 3);

        //Post-condtions
        uint balAlice_oz1 = ozERC20_1.balanceOf(alice);
        uint balAlice_oz2 = ozERC20_2.balanceOf(alice);
        uint balBob_oz2 = ozERC20_2.balanceOf(bob);
        uint balCharlie_oz1 = ozERC20_1.balanceOf(charlie);

        //Difference between non-equal stablecoin balances is less than 0.02%
        uint diff = (balAlice_oz2 + balBob_oz2) - balAlice_oz1;
        assertTrue(diff.mulDivDown(10_000, balAlice_oz1) < 2);

        //Difference between equal stablecoin balances is less than 0.01%
        diff = balAlice_oz1 - (balCharlie_oz1 * 3);
        assertTrue(diff.mulDivDown(10_000, balAlice_oz1) < 1);
    }


    function test_multiple_OZL_claim() public {

    }




}