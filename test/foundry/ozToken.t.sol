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

import "@prb/math/src/UD60x18.sol";
import {PRBMathCastingUint256} from "@prb/math/src/casting/Uint256.sol";
import {ABDKMathQuad} from "../../contracts/libraries/ABDKMathQuad.sol";

import "forge-std/console.sol";


contract ozTokenTest is TestMethods {

    using SafeERC20 for IERC20;
    using PRBMathCastingUint256 for uint;

    using ABDKMathQuad for uint;
    using ABDKMathQuad for bytes16;

    // uint SCALE = 1e18;
    // uint HALF_SCALE = 5e17;
    // uint LOG2_E = 1442695040888963407;
    // uint MAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728792003956564819967;

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

        uint ozBalanceAlicePostRewards = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostRewards = ozERC20.balanceOf(bob);

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


    function test_x() public {
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        (bytes32 oldSlot0data, bytes32 oldSharedCash, bytes32 cashSlot) = 
            _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);

        _mintOzTokens(ozERC20, alice, testToken, (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals());
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        _mintOzTokens(ozERC20, bob, testToken, ((rawAmount / 2) / 3) * 10 ** IERC20Permit(testToken).decimals());

        uint ozBalAlicePre = ozERC20.balanceOf(alice);
        uint ozBalBobPre = ozERC20.balanceOf(bob);
        console.log('ozBalAlicePre: ', ozBalAlicePre);
        console.log('ozBalBobPre: ', ozBalBobPre);

    
        console.log('totalAssets pre: ', ozERC20.totalAssets());
        console.log('totalShares pre: ', ozERC20.totalShares());

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

        uint testBalanceAlice = IERC20Permit(testToken).balanceOf(alice);
        uint testBalanceBob = IERC20Permit(testToken).balanceOf(bob);
        console.log('testBalanceAlice - pre: ', testBalanceAlice);
        console.log('testBalanceBob - post: ', testBalanceBob);

        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozBalAlicePre / 3);
        ozERC20.redeem(redeemDataAlice, alice); 

        vm.startPrank(bob);
        ozERC20.approve(address(ozDiamond), ozBalBobPre / 5);
        ozERC20.redeem(redeemDataBob, bob); 

        console.log('totalAssets post: ', ozERC20.totalAssets());
        console.log('totalShares post: ', ozERC20.totalShares());

        uint deltaAlice = IERC20Permit(testToken).balanceOf(alice) - testBalanceAlice;
        uint deltaBob = IERC20Permit(testToken).balanceOf(bob) - testBalanceBob;
        console.log('test bal gained after reedem - alice: ', deltaAlice);
        console.log('test bal gained after reedem - bob: ', deltaBob);

    
        uint ozDeltaAlice = ozBalAlicePre - ozERC20.balanceOf(alice) ;
        uint ozDeltaBob = ozBalBobPre - ozERC20.balanceOf(bob);
        console.log('oz bal lost - alice: ', ozDeltaAlice);
        console.log('oz bal lost - bob: ', ozDeltaBob);

    }


    //finish this test ^^^
    //clean up ozToken.sol
    //fix funcs in ozLoupe.sol

}