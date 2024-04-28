// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IOZL, QuoteAsset} from "../../contracts/interfaces/IOZL.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {Dir} from "../../contracts/AppStorage.sol";
import {Mock} from "./AppStorageTests.sol";

import "forge-std/console.sol";



contract Poc is TestMethods {

    using FixedPointMathLib for uint;


    function test_poc() public {
        //Pre-conditions
        if (testToken == daiAddr) testToken = usdcAddr;

        console.log('');

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

        _ozTokenPart(ozBalanceOwner, ozERC20, usdcBalanceOwnerPostOZLredeem);
    }


    function _OZLpart() private returns(ozIToken, uint) { 
        //Pre-conditions
        console.log('************ Create and Mint ozUSDC ************');

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        console.log('ozUSDC: ', address(ozERC20));
        console.log('is underlying USDC?: ', ozERC20.asset() == usdcAddr);

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        console.log('USDC balance - alice: ', amountIn);
        assertTrue(amountIn == rawAmount * 10 ** IERC20Permit(testToken).decimals());
        _changeSlippage(uint16(9900));

        _startCampaign();
        console.log('');
        console.log('^^^^^ MINTING ozUSDC ^^^^^');
        console.log('');

        _mock_rETH_ETH_unit(Mock.PREACCRUAL_UNI);
        uint rETH_ETH_preTest = OZ.rETH_ETH();
        console.log('* rETH-ETH - pre staking rewards accrual: ', rETH_ETH_preTest);

        _mintOzTokens(ozERC20, alice, testToken, amountIn); 

        uint usdcBalanceOwnerPostMint = IERC20Permit(testToken).balanceOf(alice);
        uint ozBalancePreAccrual = ozERC20.balanceOf(alice);

        assertTrue(_checkPercentageDiff(amountIn * 1e12, ozBalancePreAccrual, 5));

        console.log('ozUSDC balance - alice - pre accrual: ', ozBalancePreAccrual);
        console.log('USDC balance - alice - post ozUSDC mint: ', usdcBalanceOwnerPostMint);
        assertTrue(usdcBalanceOwnerPostMint == 0);
        console.log('');

        _accrueRewards(15);
        _mock_rETH_ETH_unit(Mock.POSTACCRUAL_UNI);

        uint rETH_ETH_postMock = OZ.rETH_ETH();

        console.log('************ Collect Admin Fee ************');

        uint ozBalanceOwner = ozERC20.balanceOf(alice);
        console.log('ozUSDC balance - alice - post accrual: ', ozBalanceOwner);
        assertTrue(ozBalanceOwner > ozBalancePreAccrual);

        console.log('* rETH-ETH post staking rewards accrual: ', rETH_ETH_postMock);
        console.log('');
        console.log('rETH_ETH_postMock: ', rETH_ETH_postMock);
        console.log('rETH_ETH_preTest: ', rETH_ETH_preTest); //<-------
        console.log('');
        assertTrue(rETH_ETH_postMock > rETH_ETH_preTest);

        console.log('rETH balance - admin - pre fee charge: ', IERC20Permit(rEthAddr).balanceOf(owner));
        assertTrue(IERC20Permit(rEthAddr).balanceOf(owner) == 0);
        
        assertTrue(OZ.chargeOZLfee());
        console.log('');
        console.log('^^^^^ COLLECTING FEE ^^^^^');
        console.log('');

        console.log('rETH balance - admin - post fee charge: ', IERC20Permit(rEthAddr).balanceOf(owner));
        assertTrue(IERC20Permit(rEthAddr).balanceOf(owner) > 0);

        console.log('');
        console.log('************ Claim OZL ************');

        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlBalancePre = OZL.balanceOf(alice);
        console.log('OZL balance - alice - pre claim: ', ozlBalancePre);
        assertTrue(ozlBalancePre == 0);

        vm.prank(alice);
        OZ.claimReward();
        console.log('');
        console.log('^^^^^ CLAIMING OZL ^^^^^');
        console.log('');

        //Post-condtions
        uint ozlBalancePost = OZL.balanceOf(alice);
        console.log('OZL balance - alice - post claim: ', ozlBalancePost);
        assertTrue(ozlBalancePost > ozlBalancePre);
        
        console.log('OZL/USD rate: ', OZL.getExchangeRate());
        assertTrue(OZL.getExchangeRate() > 1);
        console.log('');

        return (ozERC20, ozBalanceOwner);
    }



    function _ozTokenPart(uint ozBalanceOwner, ozIToken ozERC20, uint usdcBalanceOwnerPostOZLredeem) private {
        console.log('************ Redeem ozUSDC for USDC ************');

        console.log('ozUSDC balance - alice - pre redeem: ', ozERC20.balanceOf(alice));
        console.log('USDC balance - alice - pre redeem: ', IERC20Permit(testToken).balanceOf(alice));

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
        assertTrue(ozBalanceOwnerPostRedeem == 0);
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