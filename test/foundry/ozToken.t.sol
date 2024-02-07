// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {Type} from "./AppStorageTests.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AmountsIn} from "../../contracts/AppStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../contracts/Errors.sol";
import {Dummy1} from "./Dummy1.sol";
import {NewToken} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract ozTokenTest is TestMethods {

    using SafeERC20 for IERC20;

    //Tests that the try/catch on ozToken's mint() catches errors on safeTransfers 
    function test_mint_catch_internal_errors() public {
        //Pre-conditions  
        NewToken memory ozToken1 = NewToken("Ozel-ERC20-1", "ozERC20-1");
        NewToken memory wozToken1 = NewToken("Wrapped Ozel-ERC20-1", "wozERC20-1");

        (address newOzToken1,) = OZ.createOzToken(usdtAddr, ozToken1, wozToken1);

        ozIToken ozERC20_1 = ozIToken(newOzToken1);

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        (bytes memory data) = _createDataOffchain(
            ozERC20_1, amountIn, ALICE_PK, alice, testToken, Type.IN
        );

        (uint[] memory minAmountsOut,,,) = HelpersLib.extract(data);

        vm.startPrank(alice);
        IERC20(testToken).safeApprove(address(OZ), amountIn);

        AmountsIn memory amounts = AmountsIn(
            amountIn,
            minAmountsOut
        );

        //Actions
        vm.expectRevert(
            abi.encodeWithSelector(OZError22.selector, 'SafeERC20: low-level call failed')
        );

        ozERC20_1.mint(abi.encode(amounts, alice), alice);         
        vm.stopPrank();
    }


    //Tests that the try/catch on ozToken's redeem() catches errors on safeTransfers
    function test_redeem_catch_internal_errors() public {
        //Pre-conditions
        _changeSlippage(uint16(9900));
        _dealUnderlying(Quantity.BIG, false);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceOzUsdcAlice = ozERC20.balanceOf(alice);
        assertTrue(balanceOzUsdcAlice > 977_000 * 1 ether && balanceOzUsdcAlice < 1_000_000 * 1 ether);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(
            ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT
        );

        //Actions
        vm.startPrank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(OZError22.selector, 'STF')
        );
        ozERC20.redeem(redeemData, alice); 

        vm.stopPrank();
    }


    function test_minting_different_owner_msgSender() public returns(Dummy1, ozIToken) {
        //Pre-conditions  
        NewToken memory ozToken = NewToken("Ozel-ERC20", "ozERC20");
        NewToken memory wozToken = NewToken("Wrapped Ozel-ERC20", "wozERC20");

        (address newOzToken,) = OZ.createOzToken(testToken, ozToken, wozToken);

        ozIToken ozERC20 = ozIToken(newOzToken);

        _startCampaign();

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        Dummy1 dummy1 = new Dummy1(address(ozERC20), address(OZ));

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        //Actions
        bool success = dummy1.mintOz(testToken, amountIn); 
        assertTrue(success);

        uint secs = 15;
        _accrueRewards(secs);

        uint claimed = OZ.claimReward();
        vm.stopPrank();

        //Post-conditions
        vm.clearMockedCalls();
        uint ozBalanceAlice = ozERC20.balanceOf(alice);

        assertTrue(ozBalanceAlice > 99 * 1e18 && ozBalanceAlice < rawAmount * 1e18);
        assertTrue((_getRewardRate() * secs) / 100 == claimed / 100);

        return (dummy1, ozERC20);
    }


    function test_redeeming_different_owner_msgSender() public {
        //Pre-conditions
        NewToken memory ozToken = NewToken("Ozel-ERC20", "ozERC20");
        NewToken memory wozToken = NewToken("Wrapped Ozel-ERC20", "wozERC20");

        (address newOzToken,) = OZ.createOzToken(testToken, ozToken, wozToken);

        ozIToken ozERC20 = ozIToken(newOzToken);

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        Dummy1 dummy1 = new Dummy1(address(ozERC20), address(OZ));

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        bool success = dummy1.mintOz(testToken, amountIn); 
        assertTrue(success);
        
        uint ozBalanceAlicePre = ozERC20.balanceOf(alice);
        uint testTokenBalanceAlicePre = IERC20(testToken).balanceOf(alice);

        //Action
        ozERC20.approve(address(OZ), ozBalanceAlicePre);
        success = dummy1.redeemOz(ozBalanceAlicePre);
        assertTrue(success);

        vm.stopPrank();

        //Post-conditions
        uint ozBalanceAlicePost = ozERC20.balanceOf(alice);
        uint testTokenBalanceAlicePost = IERC20(testToken).balanceOf(alice);

        assertTrue(ozBalanceAlicePre > 99 * 1e18 && ozBalanceAlicePre < rawAmount * 1e18);
        assertTrue(ozBalanceAlicePost == 0);
        assertTrue(testTokenBalanceAlicePre == 0);
        assertTrue(testTokenBalanceAlicePost > 99 * 1e18 && testTokenBalanceAlicePost < rawAmount * 1e18);


    }
}