// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";


contract MultipleTokensTest is TestMethods {

    //Tests the creation of different ozTokens and that their minting of tokens is 
    //done properly. 
    function test_createAndMint_two_ozTokens() public {
        //Pre-conditions
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();
        
        ozIToken ozERC20_1 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20-1", "ozERC20_1"
        ));

        ozIToken ozERC20_2 = ozIToken(OZ.createOzToken(
            secondTestToken, "Ozel-ERC20-2", "ozERC20_2"
        ));
        

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountInFirst = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        uint amountInSecond = (rawAmount / 2) * 10 ** IERC20Permit(secondTestToken).decimals();

        //Actions
        _startCampaign();
        _mintOzTokens(ozERC20_1, alice, testToken, amountInFirst);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        _mintOzTokens(ozERC20_2, alice, secondTestToken, amountInSecond);

        //Pre-conditions
        uint ozBalance_1 = ozERC20_1.balanceOf(alice);
        uint ozBalance_2 = ozERC20_2.balanceOf(alice);

        uint amountInSecond_18dec = amountInSecond * 1e12;

        assertTrue(ozBalance_1 < amountInFirst && ozBalance_1 > (amountInFirst - 1 * 1e18));
        assertTrue(ozBalance_2 < amountInSecond_18dec && ozBalance_2 > (amountInSecond_18dec - 1 * 1e18));
    }

    
    //Tests that the OZL reward of one user is properly claimed with two ozTokens
    function test_claim_OZL_two_ozTokens() public {
        //Pre-conditions
        test_createAndMint_two_ozTokens();

        uint secs = 15;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        //Action
        vm.prank(alice);
        uint claimedReward = OZ.claimReward();

        //Post-condition
        uint rewardRate = _getRewardRate();
        assertTrue(claimedReward / 100 == (rewardRate * secs) / 100);
    }




}