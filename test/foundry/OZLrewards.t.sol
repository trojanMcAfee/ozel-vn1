// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
import {Type} from "./AppStorageTests.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {AmountsIn} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract OZLrewardsTest is TestMethods {

    //Initialze OZL distribution campaign 
    function _startCampaign() private {
        vm.startPrank(owner);
        OZ.setRewardsDuration(campaignDuration);
        OZ.notifyRewardAmount(communityAmount);
        vm.stopPrank();
    }

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


    function test_distribute() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        _startCampaign();

        //---- mint ozTokens ----
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        (bytes memory data) = _createDataOffchain(
            ozERC20, amountIn, ALICE_PK, alice, Type.IN
        );

        (uint[] memory minAmountsOut,,,) = HelpersLib.extract(data);

        vm.startPrank(alice);
        IERC20Permit(testToken).approve(address(OZ), amountIn);

        AmountsIn memory amounts = AmountsIn(
            amountIn,
            minAmountsOut[0],
            minAmountsOut[1]
        );

        bytes memory mintData = abi.encode(amounts, alice);
        ozERC20.mint(mintData); 
        
        vm.stopPrank();
        //---- end minting ----

        // console.log('time - pre: ', block.timestamp);
        uint secs = 10;
        vm.warp(block.timestamp + secs);
        // console.log('time - post: ', block.timestamp);

        uint ozlEarned = OZ.earned(alice);
        console.log('ozlEarned: ', ozlEarned);

        uint rewardsEarned = OZ.getRewardRate() * secs;
        console.log('rewardsEarned: ', rewardsEarned);

    }


}