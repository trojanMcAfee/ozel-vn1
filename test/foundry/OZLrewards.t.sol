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

        uint rewardRate =  OZ.getRewardRate();
        assertTrue(rewardRate == communityAmount / campaignDuration);
    }


    //tests that the distribution of rewards is properly working with the rewardRate assigned,
    //and that it's been added to the circulating supply.
    function test_distribute() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        //Actions
        _startCampaign();
        _mintOzTokens(ozERC20);

        uint secs = 10;
        vm.warp(block.timestamp + secs);

        //Post-conditions
        uint ozlEarned = OZ.earned(alice);
        uint rewardsEarned = OZ.getRewardRate() * secs;
        uint earnedDiff = rewardsEarned - ozlEarned;

        assertTrue(earnedDiff <= 1 && earnedDiff >= 0);

        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlClaimed = OZL.balanceOf(alice);
        uint circulatingSupply = OZL.getCirculatingSupply();

        assertTrue(ozlClaimed == 0);
        assertTrue(circulatingSupply == 0);

        vm.prank(alice);
        OZ.claimReward();

        ozlClaimed = OZL.balanceOf(alice);
        assertTrue(ozlClaimed == ozlEarned);

        circulatingSupply = OZL.getCirculatingSupply();
        assertTrue(ozlClaimed == circulatingSupply);
    }


}