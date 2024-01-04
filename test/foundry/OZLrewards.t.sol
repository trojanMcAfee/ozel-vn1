// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";

import "forge-std/console.sol";


contract OZLrewardsTest is TestMethods {

    //Initialze OZL distribution campaign 
    function _startCampaign() private {
        vm.startPrank(owner);
        OZ.setRewardsDuration(campaignDuration);
        OZ.notifyRewardAmount(communityAmount);
        vm.stopPrank();
    }


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


}