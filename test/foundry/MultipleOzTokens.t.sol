// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";


contract MultipleOzTokensTest is TestMethods {

    //Tests the creation of different ozTokens and that their minting of tokens is 
    //done properly. 
    function test_createAndMint_two_ozTokens_oneUser() public returns(
        ozIToken, ozIToken, uint, uint
    ) {
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

        //Actions
        _startCampaign();
        _mintOzTokens(ozERC20_1, alice, testToken, amountInFirst);
        _mintOzTokens(ozERC20_2, alice, secondTestToken, amountInSecond);

        //Pre-conditions
        uint ozBalance_1 = ozERC20_1.balanceOf(alice);
        uint ozBalance_2 = ozERC20_2.balanceOf(alice);

        uint amountInSecond_18dec = amountInSecond * 1e12;

        assertTrue(ozBalance_1 < amountInFirst && ozBalance_1 > (amountInFirst - 1 * 1e18));
        assertTrue(ozBalance_2 < amountInSecond_18dec && ozBalance_2 > (amountInSecond_18dec - 1 * 1e18));

        return (ozERC20_1, ozERC20_2, amountInFirst, amountInSecond);
    }

    
    //Tests that the OZL reward of one user is properly claimed with two ozTokens
    function test_claim_OZL_two_ozTokens() public {
        //Pre-conditions
        test_createAndMint_two_ozTokens_oneUser();

        uint secs = 15;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        //Action
        vm.prank(alice);
        uint claimedReward = OZ.claimReward();

        //Post-condition
        uint rewardRate = _getRewardRate();
        assertTrue(claimedReward / 1000 == (rewardRate * secs) / 1000);
    }


    //Tests that two users can claim OZL rewards from minting from the same ozToken
    function test_two_ozTokens_twoUsers_same_mint() public {
        //Pre-conditions
        (ozIToken ozERC20_1, ozIToken ozERC20_2, uint amountInFirst,) =
             test_createAndMint_two_ozTokens_oneUser();

        _mintOzTokens(ozERC20_1, bob, testToken, amountInFirst);

        uint secs = 15;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        //Actions
        vm.prank(alice);
        uint rewardsAlice = OZ.claimReward();

        vm.prank(bob);
        uint rewardsBob = OZ.claimReward();

        //Post-condtions
        uint rewardRate = _getRewardRate();

        uint ozlBalanceAlice_1 = ozERC20_1.balanceOf(alice);
        uint ozlBalanceBob_1 = ozERC20_1.balanceOf(bob);
        uint ozlBalanceAlice_2 = ozERC20_2.balanceOf(alice);

        assertTrue(ozlBalanceAlice_1 == ozlBalanceBob_1);
        assertTrue(ozlBalanceAlice_2 > 0);

        assertTrue((rewardsBob + rewardsAlice) / 1000 == (rewardRate * secs) / 1000);
        assertTrue(rewardsBob < rewardsAlice);
    }


    function test_two_ozTokens_twoUsers_different_mint() public {
        //Pre-conditions
        (, ozIToken ozERC20_2,, uint amountInSecond) =
             test_createAndMint_two_ozTokens_oneUser();

        _mintOzTokens(ozERC20_2, bob, testToken, amountInSecond); //secondTestToken

        uint secs = 15;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        //Actions
        vm.prank(alice);
        uint rewardsAlice = OZ.claimReward();

        vm.prank(bob);
        uint rewardsBob = OZ.claimReward();

        //Post-condtions
        uint rewardRate = _getRewardRate();

        uint ozlBalanceAlice_2 = ozERC20_2.balanceOf(alice);
        uint ozlBalanceBob_2 = ozERC20_2.balanceOf(bob);

        assertTrue(ozlBalanceAlice_2 == ozlBalanceBob_2);
        assertTrue(ozlBalanceAlice_2 > 0);

        assertTrue((rewardsBob + rewardsAlice) / 1000 == (rewardRate * secs) / 1000);
        assertTrue(rewardsBob < rewardsAlice);


    }




}