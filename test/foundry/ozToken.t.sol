// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {Type, Dir} from "./AppStorageTests.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AmountsIn} from "../../contracts/AppStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../contracts/Errors.sol";
import {Dummy1} from "./Dummy1.sol";
import {NewToken} from "../../contracts/AppStorage.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {OracleLibrary} from "../../contracts/libraries/oracle/OracleLibrary.sol";

import "forge-std/console.sol";


contract ozTokenTest is TestMethods {

    using SafeERC20 for IERC20;


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
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

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
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

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

        _mock_ETH_USD(Dir.UP, 400);
        
        uint ozBalanceAlicePostUp = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostUp = ozERC20.balanceOf(bob);

        assertTrue(
            ozBalanceAlicePre == ozBalanceAlicePostUp &&
            ozBalanceBobPre == ozBalanceBobPostUp
        );

        _mock_rETH_ETH(Dir.UP, 200);
        _mock_rETH_ETH_pt2();

        uint ozBalanceAlicePostRewards = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostRewards = ozERC20.balanceOf(bob);

        console.log('ozBalanceAlicePostRewards: ', ozBalanceAlicePostRewards);
        console.log('ozBalanceAlicePostUp: ', ozBalanceAlicePostUp);
        console.log('ozBalanceBobPostRewards: ', ozBalanceBobPostRewards);
        console.log('ozBalanceBobPostUp: ', ozBalanceBobPostUp);

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


    function _getUniPrice(address token0_, address token1_, uint32 secs_) private view returns(uint) {
        address pool = IUniswapV3Factory(uniFactory).getPool(token0_, token1_, uniPoolFee);
        uint32 secondsAgo = secs_;
        uint BASE = 1e12;

        if (token1_ == wethAddr) BASE = 1;

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 tick = int24(tickCumulativesDelta / int32(secondsAgo));
        
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secondsAgo) != 0)) tick--;
        
        uint amountOut = OracleLibrary.getQuoteAtTick(
            tick, 1 ether, token0_, token1_
        );
    
        return amountOut * BASE;
    }



    //Tests that the accrual and redemption of rewards happens without issues when there's more
    //than one user that's being accounted for (for internal proper internal accounting of varaibles)
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
        // bytes32 originalSlot0 = 0x00010000960096000000034100000000000000010ae5499d268d75ff31b0bffd;
        // bytes32 newSlot0WithCardinality = 0x00010000960080000000034100000000000000010ae5499d268d75ff31b0bffd;

        _mock_rETH_ETH_pt1();
        // vm.store(rethWethUniPool, bytes32(0), newSlot0WithCardinality);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();
        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        uint ozBalanceBob = ozERC20.balanceOf(bob);
        assertTrue(_fm(ozBalanceBob + ozBalanceAlice) == _fm(ozERC20.totalSupply()));

        //This simulates the rETH rewards accrual.
        _mock_rETH_ETH_pt2();
        // vm.store(rethWethUniPool, bytes32(0), originalSlot0);

        uint ozBalanceAlicePostMock = ozERC20.balanceOf(alice);
        assertTrue(ozBalanceAlice < ozBalanceAlicePostMock);

        bytes memory redeemData = OZ.getRedeemData(
            ozBalanceAlicePostMock, 
            address(ozERC20),
            OZ.getDefaultSlippage(),
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
        assertTrue(deltaBalanceTestToken > 32 * 1e18 && deltaBalanceTestToken <= 33 * 1e18);
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
            alice
        );

        bytes memory redeemDataBob = OZ.getRedeemData(
            ozBalBobPre / 5,
            address(ozERC20),
            OZ.getDefaultSlippage(),
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


    //make all tests pass
    //clean up ozToken.sol
    //fix funcs in ozLoupe.sol

}