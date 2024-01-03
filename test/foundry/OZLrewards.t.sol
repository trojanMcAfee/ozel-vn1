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


    function test_rewards() public {

        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        _startCampaign();

        IOZL OZL = IOZL(address(ozlProxy));

        uint bal = OZL.balanceOf(address(OZ));
        console.log('oz bal: ', bal);

        uint x = OZL.balanceOf(address(ozlProxy));
        console.log('OZL own bal - post: ', x);

        uint rate =  OZ.getRewardRate();
        console.log('rate: ', rate);

    }


}