// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {MockStorage} from "./MockStorage.sol";
import {AmountsIn} from "../../../contracts/AppStorage.sol";
import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";

// import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
// import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import {Oracle} from "@uniswap/v3-core/contracts/libraries/Oracle.sol";

// import {Oracle} from "../../../contracts/libraries/oracle/Oracle.sol";
import {OracleLibrary} from "../../../contracts/libraries/oracle/OracleLibrary.sol";

import "forge-std/console.sol";



contract MocksTests is MockStorage, TestMethods {

    using FixedPointMathLib for uint;

    
    function test_chainlink_feeds() public {
        uint mockPriceRETH = OZ.rETH_ETH();
        assertTrue(mockPriceRETH == rETHPreAccrual);

        uint mockPriceETH = OZ.ETH_USD();
        assertTrue(mockPriceETH == currentPriceETH);
    }

    //-----------

    function test_redeem_rewards_mock_chainlink() public returns(uint, uint, uint) {
        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);       

        uint reth_eth_current = OZ.rETH_ETH();
        uint reth_usd_preAccrual = OZ.rETH_USD(); 

        console.log('');
        console.log('reth_eth - pre accrual: ', reth_eth_current);
        console.log('reth_usd - pre accrual: ', reth_usd_preAccrual);
        console.log('');

        uint decimals = 10 ** IERC20Permit(testToken).decimals();

        uint amountIn = (rawAmount / 3) * decimals;

        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);

        // console.log('ozBalanceAlice: ', ozBalanceAlice);
        // console.log('ozBalanceBob: ', ozERC20.balanceOf(bob));

        assertTrue(ozERC20.balanceOf(bob) + ozBalanceAlice == ozERC20.totalSupply() + 1);

        //This simulates the rETH rewards accrual.
        console.log('');
        console.log('^^^^^ ACCRUAL ^^^^^');
        console.log('');

        _mock_rETH_ETH_unit();

        _mock_rETH_ETH_historical(reth_eth_current);

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
        
        assertTrue(ozERC20.balanceOf(bob) + ozERC20.balanceOf(alice) == ozERC20.totalSupply());
        assertTrue(ozBalanceAlicePostMock > ozERC20.balanceOf(alice));
        assertTrue(ozERC20.balanceOf(alice) == 0 || ozERC20.balanceOf(alice) < 0.0000011 * 1e18);
        assertTrue(balanceAliceTestTokenPreRedeem < IERC20Permit(testToken).balanceOf(alice));
        assertTrue(_checkPercentageDiff(ozBalanceAlicePostMock / 1e12, deltaBalanceTestToken, 1));

        return (amountIn, reth_usd_preAccrual, deltaBalanceTestToken);
    }

    function test_redeem_rewards_mock_TWAP() public returns(uint, uint, uint) {
        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);       

        uint reth_eth_current = OZ.rETH_ETH();
        uint reth_usd_preAccrual = OZ.rETH_USD(); 

        console.log('');
        console.log('reth_eth - pre accrual: ', reth_eth_current);
        console.log('reth_usd - pre accrual: ', reth_usd_preAccrual);
        console.log('');

        uint decimals = 10 ** IERC20Permit(testToken).decimals();

        uint amountIn = (rawAmount / 3) * decimals;

        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);

        assertTrue(ozERC20.balanceOf(bob) + ozBalanceAlice == ozERC20.totalSupply() + 1);

        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('ozBalanceAlice: ', ozBalanceAlice);
        console.log('ozBalanceBob: ', ozERC20.balanceOf(bob));

        //This simulates the rETH rewards accrual.
        console.log('');
        console.log('^^^^^ ACCRUAL ^^^^^');
        console.log('');

        // _mock_rETH_ETH_unit();
        console.log('');
        _mock_rETH_ETH_unit_TWAP();

        console.log('reth_eth - post accrual: ', OZ.rETH_ETH());
        revert('here');

        _mock_rETH_ETH_historical(reth_eth_current);

        assertTrue(OZ.rETH_ETH() > reth_eth_current);

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
        
        assertTrue(ozERC20.balanceOf(bob) + ozERC20.balanceOf(alice) == ozERC20.totalSupply());
        assertTrue(ozBalanceAlicePostMock > ozERC20.balanceOf(alice));
        assertTrue(ozERC20.balanceOf(alice) == 0 || ozERC20.balanceOf(alice) < 0.0000011 * 1e18);
        assertTrue(balanceAliceTestTokenPreRedeem < IERC20Permit(testToken).balanceOf(alice));
        assertTrue(_checkPercentageDiff(ozBalanceAlicePostMock / 1e12, deltaBalanceTestToken, 1));

        return (amountIn, reth_usd_preAccrual, deltaBalanceTestToken);
    }


    function test_rewards_mock_accounting() public {
        (uint testTokenAmountIn, uint reth_usd_preAccrual, uint deltaBalanceTestToken) = 
            test_redeem_rewards_mock_chainlink();
        console.log('');
        console.log('-------------------------');
        console.log('');

        uint eth_usd = OZ.ETH_USD();
        uint reth_usd = OZ.rETH_USD();

        console.log('eth_usd: ', eth_usd);
        console.log('reth_usd: ', reth_usd);

        uint reth_preAccrual = (testTokenAmountIn * 1e12).mulDivDown(1e18, reth_usd_preAccrual);
        console.log('reth_preAccrual: ', reth_preAccrual);

        uint reth_usd_postAccrual = OZ.rETH_USD();
        uint testToken_alledged_rewards = reth_preAccrual.mulDivDown(reth_usd_postAccrual, 1e18);
        console.log("testToken balance that should've gained: ", testToken_alledged_rewards);

        assertTrue(deltaBalanceTestToken == testToken_alledged_rewards / 1e12);
    }


    function test_z() public {
        int56 tickCumulatives_0 = 48369955231; //27639974418 (original)
        int56 tickCumulatives_1 = 48372579181; //27641473818 (original)
        uint32 secsAgo = 1800;

        int56 tickCumulativesDelta = tickCumulatives_1 - tickCumulatives_0;
        int24 tick = int24(tickCumulativesDelta / int32(secsAgo));

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secsAgo) != 0)) tick--;

        uint amountOut = OracleLibrary.getQuoteAtTick(
            tick, 1 ether, rEthAddr, wethAddr
        );

        console.log('amountOut: ', amountOut);
    }

}

