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

    
    function test_x() public {
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();
        
        //--------
        ozIToken ozERC20_1 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20-1", "ozERC20_1"
        ));

        ozIToken ozERC20_2 = ozIToken(OZ.createOzToken(
            secondTestToken, "Ozel-ERC20-2", "ozERC20_2"
        ));
        

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountInFirst = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        uint amountInSecond = (rawAmount / 2) * 10 ** IERC20Permit(secondTestToken).decimals();
        // _changeSlippage(uint16(9900));

        console.log('amount in dai: ', amountInFirst / 1e18);
        console.log('amount in usdc: ', amountInSecond / 1e6);

        //----------
        _startCampaign();

        _mintOzTokens(ozERC20_1, alice, testToken, amountInFirst);
        _mintOzTokens(ozERC20_2, alice, secondTestToken, amountInSecond);
        _mintOzTokens(ozERC20_2, bob, secondTestToken, amountInSecond);
        _mintOzTokens(ozERC20_1, charlie, testToken, amountInFirst / 3);

        uint balAlice_oz1 = ozERC20_1.balanceOf(alice);
        uint balAlice_oz2 = ozERC20_2.balanceOf(alice);
        uint balBob_oz2 = ozERC20_2.balanceOf(bob);
        uint balCharlie_oz1 = ozERC20_1.balanceOf(charlie);

        //Difference between non-equal stablecoin balances is less than 0.02%
        uint diff = (balAlice_oz2 + balBob_oz2) - balAlice_oz1;
        // assertTrue((diff * 10_000) < 2);
        assertTrue(diff.mulDivDown(10_000, balAlice_oz1) < 2);

        //Difference between equal stablecoin balances is less than 0.01%
        diff = balAlice_oz1 - (balCharlie_oz1 * 3);
        // assertTrue(diff < 1);
        assertTrue(diff.mulDivDown(10_000, balAlice_oz1) < 1);

        // console.log('bal1 - dai ****: ', bal1); 
        // console.log('bal2 - usdc ****: ', bal2);
        // console.log('bal3 - usdc ****: ', bal3);
        // console.log('bal4 - dai ****: ', bal4);

    }




}