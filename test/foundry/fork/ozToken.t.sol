// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../base/TestMethods.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {HelpersLib} from "../utils/HelpersLib.sol";
import {Type, Dir} from "../base/AppStorageTests.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AmountsIn} from "../../../contracts/AppStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../contracts/Errors.sol";
import {Dummy1} from "../mocks/Dummy1.sol";
import {Type} from "../base/AppStorageTests.sol"; 
import {AmountsOut} from "./../../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract ozERC20TokenTest is TestMethods {

    using SafeERC20 for IERC20;

    event OzTokenMinted(address owner, uint shares, uint assets);
    event OzTokenRedeemed(address owner, uint ozAmountIn, uint shares, uint assets);


    //Tests that the try/catch on ozToken's mint() catches errors on safeTransfers 
    function test_mint_catch_internal_errors() public {
        //Pre-conditions  
        (ozIToken ozERC20_1,) = _createOzTokens(usdtAddr, "1");

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
        (uint rawAmount,,) =_dealUnderlying(Quantity.BIG, false);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceOzUsdcAlice = ozERC20.balanceOf(alice);
        assertTrue(_checkPercentageDiff(rawAmount * 1 ether, balanceOzUsdcAlice, 5));

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
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _startCampaign();

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        Dummy1 dummy1 = new Dummy1(address(ozERC20), address(OZ));

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        //Actions
        bool success = dummy1.mintOz(amountIn); 
        assertTrue(success);
        vm.stopPrank();

        assertTrue(_checkPercentageDiff(rawAmount * 1e18, ozERC20.balanceOf(alice), 5));

        uint secs = 15;
        _accrueRewards(secs);

        vm.prank(alice);
        uint claimed = OZ.claimReward();

        //Post-conditions
        assertTrue(_fm3(_getRewardRate() * secs) == _fm3(claimed));

        return (dummy1, ozERC20);
    }


    function test_redeeming_different_owner_msgSender() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        uint decimals = 10 ** IERC20Permit(testToken).decimals();
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = rawAmount * decimals;

        Dummy1 dummy1 = new Dummy1(address(ozERC20), address(OZ));

        vm.startPrank(alice);
        IERC20(testToken).approve(address(OZ), amountIn);

        bool success = dummy1.mintOz(amountIn); 
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

        assertTrue(_checkPercentageDiff(rawAmount * 1e18, ozBalanceAlicePre, 5));
        assertTrue(ozBalanceAlicePost == 0);
        assertTrue(testTokenBalanceAlicePre == 0);
        assertTrue(testTokenBalanceAlicePost > 99 * decimals && testTokenBalanceAlicePost < rawAmount * decimals);
    }


    //Tests that when ETHUSD changes, ozToken balances stay the same,
    //and when rETHETH goes up (due to rewards), balances increase.
    function test_ETH_trend() public {
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //This function needs to happen before the minting.
        _mock_rETH_ETH_pt1();

        _mintOzTokens(ozERC20, alice, testToken, amountIn / 2);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlicePre = ozERC20.balanceOf(alice);
        uint ozBalanceBobPre = ozERC20.balanceOf(bob);
        console.log('ozBalanceAlicePre: ', ozBalanceAlicePre);

        _mock_ETH_USD(Dir.UP, 400);
        
        uint ozBalanceAlicePostUp = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostUp = ozERC20.balanceOf(bob);

        assertTrue(
            ozBalanceAlicePre == ozBalanceAlicePostUp &&
            ozBalanceBobPre == ozBalanceBobPostUp
        );

        //Simulates rETH accrual.
        _mock_rETH_ETH_pt2();

        uint ozBalanceAlicePostRewards = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostRewards = ozERC20.balanceOf(bob);
        console.log('ozBalanceAlicePostRewards: ', ozBalanceAlicePostRewards);

        assertTrue(
            ozBalanceAlicePostRewards > ozBalanceAlicePostUp &&
            ozBalanceBobPostRewards > ozBalanceBobPostUp
        );

        _mock_ETH_USD(Dir.DOWN, 500);

        uint ozBalanceAlicePostDown = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostDown = ozERC20.balanceOf(bob);

        assertTrue(
            ozBalanceAlicePostDown == ozBalanceAlicePostRewards &&
            ozBalanceBobPostDown == ozBalanceBobPostRewards 
        );
    }

    //------------
    

    //Tests that the accrual and redemption of rewards happens without issues when there's more
    //than one user that's being accounted for (for internal proper internal accounting of variables)
    function test_redeem_rewards() public {
        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false); 

        /**
         * Have to increase slippage even when using a SMALL dealUnderlying() because we're 
         * mocking the rETH_ETH's Chainlink rate with a higher value (to simulate rewards),
         * but the mockCall() cheatcode doesn't work on internal calls, which is what the
         * Composable Balancer pool uses to price rETH, through a Chainlink feed, when we 
         * have to swap rETH to ETH on _swapBalancer() from ozEngine.sol.
         */
        _getResetVarsAndChangeSlip();        
        
        /**
         * In order to properly test that rETH reward accrual happens with using Uniswap V3's TWAP oracle,
         * we first store an old observation on the pool's slot0, and then, for simulating the accrual,
         * we put back the original and updated observation, which contains an updated (and higher) spot price
         */
        _mock_rETH_ETH_pt1();

        uint decimals = 10 ** IERC20Permit(testToken).decimals();

        uint amountIn = (rawAmount / 3) * decimals;
        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        uint ozBalanceBob = ozERC20.balanceOf(bob);
        assertTrue(_fm(ozBalanceBob + ozBalanceAlice) == _fm(ozERC20.totalSupply()));

        //This simulates the rETH rewards accrual.
        _mock_rETH_ETH_pt2();

        uint ozBalanceAlicePostMock = ozERC20.balanceOf(alice);
        assertTrue(ozBalanceAlice < ozBalanceAlicePostMock);

        bytes memory redeemData = OZ.getRedeemData(
            ozBalanceAlicePostMock, 
            address(ozERC20),
            OZ.getDefaultSlippage(),
            alice,
            alice
        );

        uint balanceAliceTestTokenPreRedeem = IERC20Permit(testToken).balanceOf(alice);

        //ACTION
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), type(uint).max);
        ozERC20.redeem(redeemData, alice);
        vm.stopPrank();

        //POST-CONDITIONS
        uint ozBalanceAlicePostRedeem = ozERC20.balanceOf(alice);
        uint balanceAliceTestTokenPostRedeem = IERC20Permit(testToken).balanceOf(alice);
        uint deltaBalanceTestToken = balanceAliceTestTokenPostRedeem - balanceAliceTestTokenPreRedeem;
        ozBalanceAlice = ozERC20.balanceOf(alice);
        ozBalanceBob = ozERC20.balanceOf(bob);

        assertTrue(_fm(ozBalanceBob + ozBalanceAlice) == _fm(ozERC20.totalSupply()));
        assertTrue(ozBalanceAlicePostMock > ozBalanceAlicePostRedeem);
        assertTrue(ozBalanceAlicePostRedeem == 0 || ozBalanceAlicePostRedeem < 0.0000011 * 1e18);
        assertTrue(balanceAliceTestTokenPreRedeem < balanceAliceTestTokenPostRedeem);
        assertTrue(deltaBalanceTestToken > 32 * decimals  && deltaBalanceTestToken <= 33 * decimals);
    }


    //Tests minting/redeeming with several users involved and with odd, non-whole amounts
    function test_multiple_users_odd_amounts() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false); 

        _mintOzTokens(ozERC20, alice, testToken, (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals());
        _mintOzTokens(ozERC20, bob, testToken, ((rawAmount / 2) / 3) * 10 ** IERC20Permit(testToken).decimals());

        uint ozBalAlicePre = ozERC20.balanceOf(alice);
        uint ozBalBobPre = ozERC20.balanceOf(bob);

        bytes memory redeemDataAlice = OZ.getRedeemData(
            ozBalAlicePre / 3,
            address(ozERC20),
            OZ.getDefaultSlippage(),
            alice,
            alice
        );

        bytes memory redeemDataBob = OZ.getRedeemData(
            ozBalBobPre / 5,
            address(ozERC20),
            OZ.getDefaultSlippage(),
            bob,
            bob
        );

        uint testBalanceAlicePre = IERC20Permit(testToken).balanceOf(alice);
        uint testBalanceBobPre = IERC20Permit(testToken).balanceOf(bob);
        uint ozTotalSupplyPreRedeem = ozERC20.totalSupply();

        //Actions
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozBalAlicePre / 3);
        uint assetsOutAlice = ozERC20.redeem(redeemDataAlice, alice); 
        vm.stopPrank();

        vm.startPrank(bob);
        ozERC20.approve(address(ozDiamond), ozBalBobPre / 5);
        uint assetsOutBob = ozERC20.redeem(redeemDataBob, bob); 
        vm.stopPrank();

        //Post-conditions
        assertTrue(assetsOutAlice + testBalanceAlicePre == IERC20Permit(testToken).balanceOf(alice)); 
        assertTrue(assetsOutBob + testBalanceBobPre == IERC20Permit(testToken).balanceOf(bob));
        assertTrue(_fm2(ozERC20.balanceOf(alice) + ozBalAlicePre / 3) == _fm2(ozBalAlicePre));
        assertTrue(_fm2(ozERC20.balanceOf(bob) + ozBalBobPre / 5) == _fm2(ozBalBobPre));

        //Difference between balances of 0.00007325169679990087%
        assertTrue(_fm2(ozTotalSupplyPreRedeem) == _fm2(ozERC20.totalSupply() + (ozBalAlicePre / 3) + (ozBalBobPre / 5)));
    }


    /**
     * When one or both values of the minAmountsOut array is zero, it still should mint ozTokens.
     * The risk is that the caller could receive fewer ozTokens due to slippage. 
     */ 
    function test_minting_minAmountsOut_is_zero() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false); 

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();

        AmountsIn memory amountsIn = OZ.quoteAmountsIn(amountIn, OZ.getDefaultSlippage());
        amountsIn.minAmountsOut[0] = 0;

        bytes memory data = abi.encode(amountsIn, alice);

        //Actions
        vm.startPrank(alice);
        IERC20Permit(testToken).approve(address(OZ), amountIn);
        ozERC20.mint(data, alice);

        //Post-conditions
        assertTrue(
            _checkPercentageDiff(amountIn, ozERC20.balanceOf(alice), 2)
        );
    }


    //Checks that even when at least one value of minAmountsOut be 0,
    //the ozTokens can still be redeemed.
    function test_redeeming_minAmountsOut_is_zero() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        assertTrue(ozERC20.balanceOf(alice) > 33 * 10 ** IERC20Permit(testToken).decimals());

        uint ozAmountIn = ozERC20.balanceOf(alice);

        AmountsOut memory amts = OZ.quoteAmountsOut(
            ozAmountIn, address(ozERC20), OZ.getDefaultSlippage(), alice
        );

        amts.minAmountsOut[0] = 0;

        bytes memory data = abi.encode(amts, alice);

        uint underlyingBalanceAlicePreRedeem = IERC20(testToken).balanceOf(alice);
        assertTrue(underlyingBalanceAlicePreRedeem == 0);

        //Actions
        vm.startPrank(alice);        
        ozERC20.approve(address(OZ), ozAmountIn);
        ozERC20.redeem(data, alice);

        //Post-conditions
        assertTrue(IERC20(testToken).balanceOf(alice) > underlyingBalanceAlicePreRedeem);
    }


    /**
     * When the slippage for minting ozTokens is not enough (or zero), the minting operations
     * reverts with a custom error.
     */
    function test_RevertWhen_minting_slippage_is_zero() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false); 

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();

        AmountsIn memory amountsIn = OZ.quoteAmountsIn(amountIn, 0);

        bytes memory data = abi.encode(amountsIn, alice);

        vm.startPrank(alice);
        IERC20Permit(testToken).approve(address(OZ), amountIn);

        vm.expectRevert(
            abi.encodeWithSelector(OZError01.selector, "Too little received")
        );
        ozERC20.mint(data, alice);
    }


    /**
     * Tests that if at least one element from the minAmountsOut array is bigger to what
     * it should swap for based on its exchange rate (like type(uint).max), it reverts with
     * a custom error.
     */
    function test_RevertWhen_minting_one_minAmountsOut_is_uint_max() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false); 

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();

        AmountsIn memory amountsIn = OZ.quoteAmountsIn(amountIn, OZ.getDefaultSlippage());
        amountsIn.minAmountsOut[0] = type(uint).max;

        bytes memory data = abi.encode(amountsIn, alice);

        vm.startPrank(alice);
        IERC20Permit(testToken).approve(address(OZ), amountIn);
        vm.expectRevert(
            abi.encodeWithSelector(OZError01.selector, "Too little received")
        );
        ozERC20.mint(data, alice);
    }


    function test_RevertWhen_redeeming_one_minAmountsOut_is_uint_max() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        assertTrue(ozERC20.balanceOf(alice) > 33 * 10 ** IERC20Permit(testToken).decimals());

        uint ozAmountIn = ozERC20.balanceOf(alice);

        AmountsOut memory amts = OZ.quoteAmountsOut(
            ozAmountIn, address(ozERC20), OZ.getDefaultSlippage(), alice
        );

        amts.minAmountsOut[0] = type(uint).max;

        bytes memory data = abi.encode(amts, alice);

        //Actions
        vm.startPrank(alice);        
        ozERC20.approve(address(OZ), ozAmountIn);

        vm.expectRevert(
            abi.encodeWithSelector(OZError20.selector)
        );
        ozERC20.redeem(data, alice);
    }


    function test_minting_should_emit_OzTokenMinted() public {
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false); 
        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();

        bytes memory data = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice);

        uint shares = 33000000;
        uint assets = 33000000;

        vm.startPrank(alice);
        IERC20Permit(testToken).approve(address(OZ), amountIn);

        vm.expectEmit(false, false, false, true);
        emit OzTokenMinted(alice, shares, assets);

        ozERC20.mint(data, alice);
    }


    function test_redeeming_should_emit_OzTokenRedeemed() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        uint ozAmountIn = ozERC20.balanceOf(alice);

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, address(ozERC20), OZ.getDefaultSlippage(), alice, alice
        );

        uint shares = ozERC20.sharesOf(alice);
        uint assets = shares;

        //Actions + Post-conditions
        vm.startPrank(alice);        
        ozERC20.approve(address(OZ), ozAmountIn);

        vm.expectEmit(false, false, false, true);
        emit OzTokenRedeemed(alice, ozAmountIn, shares, assets);

        ozERC20.redeem(data, alice);
    }


    function test_transferShares() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        (ozIToken ozERC20, uint sharesOut) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        assertEq(sharesOut, ozERC20.sharesOf(alice));

        uint ozBalanceAlicePreTransfer = ozERC20.balanceOf(alice);
        uint ozBalanceBobPreTransfer = ozERC20.balanceOf(bob);
        assertEq(ozBalanceBobPreTransfer, 0);

        //Action
        vm.prank(alice);
        uint ozBalanceOut = ozERC20.transferShares(bob, sharesOut);
        console.log(21);

        //Post-conditions
        uint ozBalanceBobPostTransfer = ozERC20.balanceOf(bob);
        uint ozBalanceAlicePostTransfer = ozERC20.balanceOf(alice);

        assertEq(ozBalanceAlicePreTransfer, ozBalanceOut);
        assertEq(ozBalanceAlicePreTransfer, ozBalanceBobPostTransfer);
        assertEq(ozBalanceAlicePostTransfer, 0);
    }


    function test_x() public {
        //Pre-conditions
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false); 
        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();
        uint amountInBob = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();

        AmountsIn memory amountsIn = OZ.quoteAmountsIn(amountIn, OZ.getDefaultSlippage());
        bytes memory data = abi.encode(amountsIn, alice);

        //Actions
        vm.startPrank(alice);
        IERC20Permit(testToken).approve(address(OZ), amountIn);
        uint shares = ozERC20.mint(data, alice);

        _mintOzTokens(ozERC20, bob, testToken, amountInBob);

        console.log('oz balance - alice: ', ozERC20.balanceOf(alice));
        console.log('oz balance - bob: ', ozERC20.balanceOf(bob));
        console.log('shares from mint: ', shares);
        console.log('sharesOf: ', ozERC20.sharesOf(alice));
        // console.log('previewWithdraw: ', ozERC20.previewWithdraw(amountIn));
        // console.log('previewWithdraw with shares: ', ozERC20.previewWithdraw(shares));
        console.log('amountIn - alice: ', amountIn);
        console.log('amountIn - bob: ', amountInBob);
        console.log('convertToAssets: ', ozERC20.convertToOzTokens(shares, alice));

        uint ozAmountIn = ozERC20.balanceOf(alice);

        data = OZ.getRedeemData(
            ozAmountIn, address(ozERC20), OZ.getDefaultSlippage(), alice, alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(data, alice);
        console.log('');
        console.log('underlyingOut: ', underlyingOut);
    }

}