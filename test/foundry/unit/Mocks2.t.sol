// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {MockStorage} from "./MockStorage.sol";
// import {MockOzOracle} from "./mocks/MockOzOracle.sol";
import {AmountsIn, Dir} from "../../../contracts/AppStorage.sol";
import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";
import {Mock} from "../AppStorageTests.sol";
// import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
// import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import {Oracle} from "@uniswap/v3-core/contracts/libraries/Oracle.sol";

// import {Oracle} from "../../../contracts/libraries/oracle/Oracle.sol";
import {OracleLibrary} from "../../../contracts/libraries/oracle/OracleLibrary.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";    
import {Test} from "forge-std/Test.sol";       
import {Uint512} from "../../../contracts/libraries/Uint512.sol";
import {Helpers} from "../../../contracts/libraries/Helpers.sol";
import {HelpersLib} from "../HelpersLib.sol";

import "forge-std/console.sol";



contract MocksTests2 is MockStorage, TestMethods {

    using FixedPointMathLib for uint;
    using stdStorage for StdStorage;
    using Uint512 for uint;
    using Helpers for uint;
    using HelpersLib for uint;


    function test_redeem_TWAP_rewards_mock2() public returns(uint, uint, uint) {
        if (_skip()) return (0, 0, 0);

        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);

        console.log('init USDC balance - alice: ', IERC20Permit(testToken).balanceOf(alice));

        _mock_rETH_ETH_unit(Mock.PREACCRUAL_UNI_NO_DEVIATION);

        uint reth_eth_current = OZ.rETH_ETH();
        uint reth_usd_preAccrual = OZ.rETH_USD(); 

        console.log('');
        console.log('reth_eth - pre accrual: ', reth_eth_current);
        console.log('reth_usd - pre accrual: ', reth_usd_preAccrual);
        console.log('');

        uint amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();
        console.log('USDC in to convert into ozUSDC: ', amountIn);

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
        console.log('ozBalanceAlicePostMock: ', ozBalanceAlicePostMock);
        console.log('ozBalanceBobPostMock: ', ozBalanceBobPostMock);
        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('');
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


    function test_rewards_mock_accounting2() public {
        if (_skip()) return;

        (uint testTokenAmountIn, uint reth_usd_preAccrual, uint deltaBalanceTestToken) = 
            test_redeem_TWAP_rewards_mock2();
        console.log('');
        console.log('-------------------------');
        console.log('');

        uint eth_usd = OZ.ETH_USD();
        uint reth_usd = OZ.rETH_USD();

        console.log('eth_usd: ', eth_usd);
        console.log('reth_usd: ', reth_usd);

        uint formatter = testToken == USDC ? 1e12 : 1;
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


}

