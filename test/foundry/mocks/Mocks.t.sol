// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../base/TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {MockStorage} from "./MockStorage.sol";
import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";
import {Mock, Dir} from "../base/AppStorageTests.sol";
// import {ModifiersTests} from "../base/ModifiersTests.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";    
import {Test} from "forge-std/Test.sol";       
import {Uint512} from "../../../contracts/libraries/Uint512.sol";
import {Helpers} from "../../../contracts/libraries/Helpers.sol";
import {HelpersLib} from "../utils/HelpersLib.sol";

import "forge-std/console.sol";

struct Slot0 {
    uint160 sqrtPriceX96;
    int24 tick;
    uint16 observationIndex;
    uint16 observationCardinality;
    uint16 observationCardinalityNext;
    uint8 feeProtocol;
    bool unlocked;
}



contract MocksTests is MockStorage, TestMethods {

    using FixedPointMathLib for uint;
    using stdStorage for StdStorage;
    using Uint512 for uint;
    using Helpers for uint;
    using HelpersLib for uint;


    function test_redeem_TWAP_rewards_mock() skipOrNot public returns(uint, uint, uint) {
        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);

        _mock_rETH_ETH_unit(Mock.PREACCRUAL_UNI_NO_DEVIATION);

        uint reth_eth_current = OZ.rETH_ETH();
        uint reth_usd_preAccrual = OZ.rETH_USD(); 

        console.log('');
        console.log('reth_eth - pre accrual: ', reth_eth_current);
        console.log('reth_usd - pre accrual: ', reth_usd_preAccrual);
        console.log('');

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();

        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);

        assertTrue(ozERC20.balanceOf(bob) + ozBalanceAlice == ozERC20.totalSupply());

        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('ozBalanceAlice: ', ozBalanceAlice);
        console.log('ozBalanceBob: ', ozERC20.balanceOf(bob));

        //This simulates the rETH rewards accrual.
        console.log('');
        console.log('^^^^^ ACCRUAL ^^^^^');
        console.log('');

        _mock_rETH_ETH_unit(Mock.POSTACCRUAL_UNI);

        assertTrue(OZ.rETH_ETH() > reth_eth_current);

        console.log('reth_eth - post accrual: ', OZ.rETH_ETH());
        console.log('reth_usd - post accrual: ', OZ.rETH_USD());
        console.log('');

        uint ozBalanceAlicePostMock = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostMock = ozERC20.balanceOf(bob);

        assertTrue(ozBalanceAlice < ozBalanceAlicePostMock);
        assertTrue(ozBalanceAlicePostMock + ozBalanceBobPostMock == ozERC20.totalSupply());

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

        console.log('');
        console.log('^^^^^ REDEEM ^^^^^');
        console.log('');

        //POST-CONDITIONS
        console.log('ozBalanceAlicePostRedeem: ', ozERC20.balanceOf(alice));
        console.log('');

        console.log('balanceAliceTestTokenPostRedeem: ', IERC20Permit(testToken).balanceOf(alice));
        console.log('balanceAliceTestTokenPreRedeem: ', balanceAliceTestTokenPreRedeem);
        console.log('');
        
        uint deltaBalanceTestToken = IERC20Permit(testToken).balanceOf(alice) - balanceAliceTestTokenPreRedeem;
        console.log('testToken gained after redeem: ', deltaBalanceTestToken);
        
        console.log('');
        console.log('ozERC20.balanceOf(bob): ', ozERC20.balanceOf(bob));
        console.log('ozERC20.balanceOf(alice): ', ozERC20.balanceOf(alice));
        console.log('ozERC20.totalSupply(): ', ozERC20.totalSupply());
        console.log('');
        assertTrue(ozERC20.balanceOf(bob) + ozERC20.balanceOf(alice) == ozERC20.totalSupply());
        assertTrue(ozBalanceAlicePostMock > ozERC20.balanceOf(alice));
        assertTrue(ozERC20.balanceOf(alice) == 0 || ozERC20.balanceOf(alice) < 0.0000011 * 1e18);
        assertTrue(balanceAliceTestTokenPreRedeem < IERC20Permit(testToken).balanceOf(alice));
    
        uint formatter = testToken == usdcAddr ? 1e12 : 1;
        assertTrue(_checkPercentageDiff(ozBalanceAlicePostMock / formatter, deltaBalanceTestToken, 1));

        return (amountIn, reth_usd_preAccrual, deltaBalanceTestToken);
    }


    function test_rewards_mock_accounting() skipOrNot public {
        // if (_skip()) return;

        (uint testTokenAmountIn, uint reth_usd_preAccrual, uint deltaBalanceTestToken) = 
            test_redeem_TWAP_rewards_mock();
        console.log('');
        console.log('-------------------------');
        console.log('');

        uint eth_usd = OZ.ETH_USD();
        uint reth_usd = OZ.rETH_USD();

        console.log('eth_usd: ', eth_usd);
        console.log('reth_usd: ', reth_usd);

        uint formatter = USDC(testToken) ? 1e12 : 1;
        uint reth_preAccrual = (testTokenAmountIn * formatter).mulDivDown(1e18, reth_usd_preAccrual);
        console.log('reth_preAccrual: ', reth_preAccrual);

        uint reth_usd_postAccrual = OZ.rETH_USD();
        uint testToken_alledged_rewards = reth_preAccrual.mulDivDown(reth_usd_postAccrual, 1e18);
        console.log("testToken balance that should've gained: ", testToken_alledged_rewards);

        if (testToken == usdcAddr) {
            assertTrue(deltaBalanceTestToken == testToken_alledged_rewards / 1e12);
        } else {
            assertTrue(_fm(deltaBalanceTestToken, 4) == _fm(testToken_alledged_rewards, 4));
        }
    }


    function test_project_destroyer() public {
        if (testToken == usdcAddr) testToken = daiAddr;

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //This function needs to happen before the minting.
        _mock_rETH_ETH_pt1();

        _mintOzTokens(ozERC20, alice, testToken, amountIn / 2);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlicePre = ozERC20.balanceOf(alice);
        uint ozBalanceBobPre = ozERC20.balanceOf(bob);
    
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
        console.log('ozBalanceAlicePostRewards - pre Dir.DOWN mock: ', ozBalanceAlicePostRewards);
        console.log('');

        assertTrue(
            ozBalanceAlicePostRewards > ozBalanceAlicePostUp &&
            ozBalanceBobPostRewards > ozBalanceBobPostUp
        );

        console.log('ETHUSD pre Dir.DOWN mock: ', OZ.ETH_USD());

        _mock_ETH_USD(Dir.DOWN, 4217);

        console.log('ETHUSD post Dir.DOWN mock: ', OZ.ETH_USD());
        console.log('');

        console.log('ozBalanceAlice - post Dir.DOWN mock: ', ozERC20.balanceOf(alice));

        uint ozBalanceAlicePostDown = ozERC20.balanceOf(alice);
        uint ozBalanceBobPostDown = ozERC20.balanceOf(bob);

        assertTrue(
            ozBalanceAlicePostDown == ozBalanceAlicePostRewards &&
            ozBalanceBobPostDown == ozBalanceBobPostRewards 
        );

        //------------

        bytes memory data = OZ.getRedeemData(
            ozBalanceAlicePostDown, address(ozERC20), OZ.getDefaultSlippage(), alice, alice
        );

        uint balanceTestTokenPreRedeem = IERC20Permit(testToken).balanceOf(alice);
        console.log('balance testToken alice - pre redeem', balanceTestTokenPreRedeem);

        //---- mock ETHUSD swap in swapUni
        //This is for the final swap that sends the stablecoin back to the user when redeeming
        _mock_ETH_USD_swapUni();

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozBalanceAlicePostDown);
        ozERC20.redeem(data, alice);

        uint balanceTestTokenPostRedeem = IERC20Permit(testToken).balanceOf(alice);
        console.log('balance testToken alice - post redeem', balanceTestTokenPostRedeem);
        console.log('');
        console.logInt(int(balanceTestTokenPostRedeem - balanceTestTokenPreRedeem) - int(amountIn / 2));
        console.log('net profits from using the system ^^^^');
    }


}

