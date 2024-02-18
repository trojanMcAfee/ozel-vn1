// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
import {IOZLvesting} from "../../contracts/interfaces/IOZLvesting.sol";
import {OZLvesting} from "../../contracts/OZLvesting.sol";

import "forge-std/console.sol";


contract OZLvestingTest is TestMethods {

    //Tests the vesting and releasing of vested tokens depending on its time campaign, 
    //and adds the tokens to the circulating supply
    function test_vesting_releasing_teamAlloc() public {
        //Pre-conditions
        assertTrue(address(teamVesting) != address(0));
        assertTrue(teamVesting.releasable() == 0);
        assertTrue(teamVesting.vestedAmount(uint64(block.timestamp)) == 0);
        IOZL OZL = IOZL(address(ozlProxy));
        
        vm.warp(startTimeVesting + block.timestamp + 182 days); //Action 1

        uint relesable = teamVesting.releasable();
        uint vested = teamVesting.vestedAmount();
        assertTrue(relesable == vested);

        (,uint ciculatingSupplyPre,,,) = OZ.getRewardsData();
        assertTrue(ciculatingSupplyPre == 0);

        teamVesting.release(); //Action 2
        uint beneficiaryBalance = OZL.balanceOf(teamBeneficiary);
        assertTrue(beneficiaryBalance == vested);

        (,uint ciculatingSupplyPost,,,) = OZ.getRewardsData();
        assertTrue(ciculatingSupplyPost == beneficiaryBalance);

        relesable = teamVesting.releasable();
        vested = teamVesting.vestedAmount();
    
        vm.warp(block.timestamp + 183 days); //Action 3

        relesable = teamVesting.releasable();
        assertTrue(relesable + beneficiaryBalance == teamAmount);

        vested = teamVesting.vestedAmount();
        assertTrue(vested == teamAmount);
    }


    function test_vesting_releasing_guildAlloc() public {
        //Pre-conditions
        assertTrue(address(guildVesting) != address(0));
        assertTrue(guildVesting.releasable() == 0);
        assertTrue(guildVesting.vestedAmount(uint64(block.timestamp)) == 0);
        IOZL OZL = IOZL(address(ozlProxy));
        
        vm.warp(startTimeVesting + block.timestamp + 182 days); //Action 1

        uint relesable = guildVesting.releasable();
        uint vested = guildVesting.vestedAmount();
        assertTrue(relesable == vested);

        (,uint ciculatingSupplyPre,,,) = OZ.getRewardsData();
        assertTrue(ciculatingSupplyPre == 0);

        guildVesting.release(); //Action 2
        uint beneficiaryBalance = OZL.balanceOf(protocolGuildSplit);
        assertTrue(beneficiaryBalance == vested);

        (,uint ciculatingSupplyPost,,,) = OZ.getRewardsData();
        assertTrue(ciculatingSupplyPost == beneficiaryBalance);

        relesable = guildVesting.releasable();
        vested = guildVesting.vestedAmount();
    
        vm.warp(block.timestamp + 183 days); //Action 3

        relesable = guildVesting.releasable();
        assertTrue(relesable + beneficiaryBalance == guildAmount);

        vested = guildVesting.vestedAmount();
        assertTrue(vested == guildAmount);
    }


    function test_pendingAlloc_and_allocate() public {
        //Pre-conditions
        IOZL OZL = IOZL(address(ozlProxy));

        uint remainder = OZL.totalSupply() - teamAmount - guildAmount;
        assertTrue(OZL.pendingAlloc() == remainder);

        OZLvesting aliceVesting = _createVestingWallet(alice);
        uint toAllocate = 10_000_000 * 1e18;

        //Action 1
        vm.prank(owner);
        IOZLvesting aliceVestingTypeSafe = IOZLvesting(address(payable(aliceVesting)));
        OZL.allocate(aliceVestingTypeSafe, toAllocate);
        assertTrue(OZL.pendingAlloc() == remainder - toAllocate);

        //Action 2
        vm.warp(startTimeVesting + block.timestamp + 182 days);
        aliceVesting.release();

        //Post-conditions
        uint beneficiaryBalance = OZL.balanceOf(alice);
        uint vested = aliceVesting.vestedAmount();
        assertTrue(beneficiaryBalance == vested);

        (,uint ciculatingSupply,,,) = OZ.getRewardsData();
        assertTrue(ciculatingSupply == beneficiaryBalance);
    }




}