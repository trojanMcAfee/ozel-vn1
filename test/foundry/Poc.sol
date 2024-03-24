// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IOZL, QuoteAsset} from "../../contracts/interfaces/IOZL.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";



contract Poc is TestMethods {

    using FixedPointMathLib for uint;


    function test_redeem_rewards_chainlink() public {
        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false); 

        _getResetVarsAndChangeSlip();        
        
        uint pastAnswer = 1085995250282916400;
        _mock_rETH_ETH_historical(pastAnswer);

        uint reth_eth_current = OZ.rETH_ETH();
        console.log('reth_eth - pre accrual: ', reth_eth_current);

        uint decimals = 10 ** IERC20Permit(testToken).decimals();

        uint amountIn = (rawAmount / 3) * decimals;
        console.log('amountIn testToken: ', amountIn);

        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        console.log('ozBalanceAlice: ', ozBalanceAlice);

        assertTrue(_fm(ozERC20.balanceOf(bob) + ozBalanceAlice) == _fm(ozERC20.totalSupply()));

        //This simulates the rETH rewards accrual.
        _mock_rETH_ETH();
        _mock_rETH_ETH_historical(reth_eth_current);

        assertTrue(OZ.rETH_ETH() > reth_eth_current);
        console.log('reth_eth - post accrual: ', OZ.rETH_ETH());

        uint ozBalanceAlicePostMock = ozERC20.balanceOf(alice);
        console.log('ozBalanceAlicePostMock: ', ozBalanceAlicePostMock);
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
        
        console.log('ozBalanceAlicePostRedeem: ', ozERC20.balanceOf(alice));
        console.log('balanceAliceTestTokenPostRedeem: ', IERC20Permit(testToken).balanceOf(alice));
        console.log('balanceAliceTestTokenPreRedeem: ', balanceAliceTestTokenPreRedeem);
        
        uint deltaBalanceTestToken = IERC20Permit(testToken).balanceOf(alice) - balanceAliceTestTokenPreRedeem;
        console.log('testToken gained after redeem: ', deltaBalanceTestToken);
        
        assertTrue(_fm(ozERC20.balanceOf(bob) + ozERC20.balanceOf(alice)) == _fm(ozERC20.totalSupply()));
        assertTrue(ozBalanceAlicePostMock > ozERC20.balanceOf(alice));
        assertTrue(ozERC20.balanceOf(alice) == 0 || ozERC20.balanceOf(alice) < 0.0000011 * 1e18);
        assertTrue(balanceAliceTestTokenPreRedeem < IERC20Permit(testToken).balanceOf(alice));
        assertTrue(deltaBalanceTestToken > 32 * decimals  && deltaBalanceTestToken <= 33 * decimals);
    }






    //--------------------

    function test_poc() public {
        //Pre-conditions
        uint rETH_ETH_preTest = OZ.rETH_ETH();
        (ozIToken ozERC20, uint ozBalanceOwner) = _OZLpart();

        IOZL OZL = IOZL(address(ozlProxy));

        uint ozlBalanceAlice = OZL.balanceOf(alice);

        uint[] memory minAmountsOut = _getMinsOut(ozlBalanceAlice, rETH_ETH_preTest, OZL);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, _getPermitHashOZL(alice, address(OZ), ozlBalanceAlice));
        
        console.log('************ Redeem OZL for USDC ************');
        uint usdcBalanceOwnerPreOZLredeem = IERC20Permit(testToken).balanceOf(alice);
        console.log('USDC balance - alice - pre OZL redeem: ', usdcBalanceOwnerPreOZLredeem);

        vm.startPrank(alice);
        OZL.permit(
            alice,
            address(OZ),
            ozlBalanceAlice,
            block.timestamp,
            v, r, s
        );

        OZL.redeem(
            alice,
            alice,
            testToken,
            ozlBalanceAlice,
            minAmountsOut
        );

        console.log('');
        console.log('^^^^^ REDEEMING OZL ^^^^^');
        console.log('');

        vm.stopPrank();

        //Post-condtions
        uint usdcBalanceOwnerPostOZLredeem = IERC20Permit(testToken).balanceOf(alice);
        console.log('USDC balance - alice - post OZL redeem: ', usdcBalanceOwnerPostOZLredeem);

        console.log('OZL/USD rate - post OZL redeemption: ', OZL.getExchangeRate());
        console.log('');

        //-------
        _ozTokenPart(ozBalanceOwner, ozERC20, usdcBalanceOwnerPostOZLredeem);
    }


    function _OZLpart() private returns(ozIToken, uint) { 
        //Pre-conditions
        // _mock_rETH_ETH_pt1();
        // uint rETH_ETH_preTest = OZ.rETH_ETH();

        console.log('');
        // console.log('* rETH-ETH - pre staking rewards accrual: ', rETH_ETH_preTest);
        console.log('');

        console.log('************ Create and Mint ozUSDC ************');

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        console.log('ozUSDC: ', address(ozERC20));
        console.log('is underlying USDC?: ', ozERC20.asset() == usdcAddr);

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        console.log('USDC balance - alice: ', amountIn);
        _changeSlippage(uint16(9900));

        _startCampaign();
        console.log('');
        console.log('^^^^^ MINTING ozUSDC ^^^^^');
        console.log('');

        _mock_rETH_ETH_pt1();
        uint rETH_ETH_preTest = OZ.rETH_ETH();
        console.log('* rETH-ETH - pre staking rewards accrual: ', rETH_ETH_preTest);

        _mintOzTokens(ozERC20, alice, testToken, amountIn); 

        uint ozBalanceOwner = ozERC20.balanceOf(alice);
        uint usdcBalanceOwnerPostMint = IERC20Permit(testToken).balanceOf(alice);

        console.log('ozUSDC balance - alice: ', ozBalanceOwner);
        console.log('USDC balance - alice - post ozUSDC mint: ', usdcBalanceOwnerPostMint);
        console.log('');

        _accrueRewards(15);
        _mock_rETH_ETH_pt2();

        uint rETH_ETH_postMock = OZ.rETH_ETH();
        console.log('************ Collect Admin Fee ************');
        console.log('ozUSDC balance - alice - post accrual: ', ozERC20.balanceOf(alice));
        console.log('* rETH-ETH post staking rewards accrual: ', rETH_ETH_postMock);

        revert('hereeee');

        console.log('rETH balance - admin - pre fee charge: ', IERC20Permit(rEthAddr).balanceOf(owner));
        
        OZ.chargeOZLfee();
        console.log('');
        console.log('^^^^^ COLLECTING FEE ^^^^^');
        console.log('');

        console.log('rETH balance - admin - post fee charge: ', IERC20Permit(rEthAddr).balanceOf(owner));

        console.log('');
        console.log('************ Claim OZL ************');
        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlBalancePre = OZL.balanceOf(alice);
        console.log('OZL balance - alice - pre claim: ', ozlBalancePre);

        vm.prank(alice);
        OZ.claimReward();
        console.log('');
        console.log('^^^^^ CLAIMING OZL ^^^^^');
        console.log('');

        //Post-condtions
        uint ozlBalancePost = OZL.balanceOf(alice);
        console.log('OZL balance - alice - post claim: ', ozlBalancePost);
        
        console.log('OZL/USD rate: ', OZL.getExchangeRate());
        console.log('');

        return (ozERC20, ozBalanceOwner);
    }



    function _ozTokenPart(uint ozBalanceOwner, ozIToken ozERC20, uint usdcBalanceOwnerPostOZLredeem) private {
        console.log('************ Redeem ozUSDC for USDC ************');
        bytes memory redeemData = OZ.getRedeemData(
            ozBalanceOwner,
            address(ozERC20),
            OZ.getDefaultSlippage(),
            alice,
            alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozBalanceOwner);
        ozERC20.redeem(redeemData, alice);
        vm.stopPrank();

        console.log('');
        console.log('^^^^^ REDEEMING ozUSDC ^^^^^');
        console.log('');

        uint ozBalanceOwnerPostRedeem = ozERC20.balanceOf(alice);
        uint usdcBalanceOwnerPostRedeem = IERC20Permit(testToken).balanceOf(alice);
        
        console.log('ozUSDC balance - alice - post redeem: ', ozBalanceOwnerPostRedeem);
        console.log('USDC balance - alice - post redeem: ', usdcBalanceOwnerPostRedeem);
        
        uint delta = usdcBalanceOwnerPostRedeem - usdcBalanceOwnerPostOZLredeem;
        console.log('USDC gained after redeeming ozUSDC: ', delta);
        console.log('');

    }


    function _getMinsOut(uint ozlBalanceAlice, uint rETH_ETH_preTest, IOZL OZL) private returns(uint[] memory) {
        uint usdToRedeem = ozlBalanceAlice * OZL.getExchangeRate() / 1 ether;

        _changeSlippage(uint16(500)); 

        uint wethToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.ETH)) / 1 ether;

        /**
         * Same situation as in test_redeem_in_stable()
         */
        uint rETH_ETH_postMock = OZ.rETH_ETH();
        uint delta_rETHrates = (rETH_ETH_postMock - rETH_ETH_preTest).mulDivDown(10_000, rETH_ETH_postMock) * 1e16;

        wethToRedeem = _applyDelta(wethToRedeem, delta_rETHrates);
        usdToRedeem = _applyDelta(usdToRedeem, delta_rETHrates);

        uint[] memory minAmountsOut = HelpersLib.calculateMinAmountsOut(
            [wethToRedeem, usdToRedeem], [OZ.getDefaultSlippage(), uint16(50)]
        );

        return minAmountsOut;
    }


}