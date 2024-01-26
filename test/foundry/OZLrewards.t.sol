// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
// import {Type} from "./AppStorageTests.sol";
// import {HelpersLib} from "./HelpersLib.sol";
// import {AmountsIn} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract OZLrewardsTest is TestMethods {

    //tests that the reward rate was properly calculated + OZL assignation to ozDiamond
    function test_rewardRate() public {
        //Pre-conditions
        OZ.createOzToken(testToken, "Ozel-ERC20", "ozERC20");
        IOZL OZL = IOZL(address(ozlProxy));

        //Action
        _startCampaign();

        //Post-conditions
        uint ozlBalanceDiamond = OZL.balanceOf(address(OZ));
        assertTrue(ozlBalanceDiamond == communityAmount);

        uint ozlBalanceOZLproxy = OZL.balanceOf(address(ozlProxy));
        assertTrue(ozlBalanceOZLproxy == totalSupplyOZL - ozlBalanceDiamond);

        uint rewardRate =  _getRewardRate();
        assertTrue(rewardRate == communityAmount / campaignDuration);
    }


    //tests that the distribution of rewards is properly working with the rewardRate assigned,
    //and that it's been added to the circulating supply.
    //tests the exchange rate also
    function test_distribute_OZL() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //Actions
        _startCampaign();
        _mintOzTokens(ozERC20, alice, testToken, amountIn);

        uint secs = 10;
        vm.warp(block.timestamp + secs);

        //Post-conditions
        uint ozlEarned = OZ.earned(alice);
        uint rewardsEarned = _getRewardRate() * secs;
        uint earnedDiff = rewardsEarned - ozlEarned;

        assertTrue(earnedDiff <= 1 && earnedDiff >= 0);

        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlClaimed = OZL.balanceOf(alice);
        uint circulatingSupply = OZL.circulatingSupply();

        assertTrue(ozlClaimed == 0);
        assertTrue(circulatingSupply == 0);

        vm.prank(alice);
        OZ.claimReward();

        ozlClaimed = OZL.balanceOf(alice);
        assertTrue(ozlClaimed == ozlEarned);

        circulatingSupply = OZL.circulatingSupply();
        assertTrue(ozlClaimed == circulatingSupply);

        //------
        // uint rate = OZL.getExchangeRate();
        // assertTrue(rate == 1);

        // uint rate = OZL.getExchangeRate();
        // console.log('rate3: ', rate); 
    }


}