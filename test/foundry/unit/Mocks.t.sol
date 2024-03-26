// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {MockStorage} from "./MockStorage.sol";

import "forge-std/console.sol";


contract MocksTests is MockStorage, TestMethods {

    
    function test_chainlink_feeds() public {
        uint mockPriceRETH = OZ.rETH_ETH();
        assertTrue(mockPriceRETH == rETHPreAccrual);

        uint mockPriceETH = OZ.ETH_USD();
        assertTrue(mockPriceETH == currentPriceETH);
    }

    //-----------

    function test_redeem_rewards_mock_chainlink() public returns(uint, uint) {
        //PRE-CONDITIONS
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);       
        
        // uint pastAnswer = 1085995250282916400;
        // _mock_rETH_ETH_historical(pastAnswer);

        uint reth_eth_current = OZ.rETH_ETH();
        uint reth_usd_preAccrual = OZ.rETH_USD(); 

        console.log('');
        console.log('reth_eth - pre accrual: ', reth_eth_current);
        console.log('reth_usd - pre accrual: ', reth_usd_preAccrual);
        console.log('');

        uint decimals = 10 ** IERC20Permit(testToken).decimals();

        uint amountIn = (rawAmount / 3) * decimals;
        console.log('amountIn testToken: ', amountIn);

        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _mintOzTokens(ozERC20, bob, testToken, amountIn);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        console.log('ozBalanceAlice: ', ozBalanceAlice);

        // assertTrue(_fm(ozERC20.balanceOf(bob) + ozBalanceAlice) == _fm(ozERC20.totalSupply()));

        //This simulates the rETH rewards accrual.
        console.log('');
        console.log('^^^^^ ACCRUAL ^^^^^');
        console.log('');

        _mock_rETH_ETH_unit();
        console.log('reth pre-revert: ', OZ.rETH_ETH());
        revert('hereeeeee22');

        _mock_rETH_ETH_historical(reth_eth_current);

        assertTrue(OZ.rETH_ETH() > reth_eth_current);

        console.log('');
        console.log('reth_eth - post accrual: ', OZ.rETH_ETH());
        console.log('reth_usd - post accrual: ', OZ.rETH_USD());
        console.log('');

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
        console.log('');

        console.log('balanceAliceTestTokenPostRedeem: ', IERC20Permit(testToken).balanceOf(alice));
        console.log('balanceAliceTestTokenPreRedeem: ', balanceAliceTestTokenPreRedeem);
        console.log('');
        
        uint deltaBalanceTestToken = IERC20Permit(testToken).balanceOf(alice) - balanceAliceTestTokenPreRedeem;
        console.log('testToken gained after redeem: ', deltaBalanceTestToken);
        
        // assertTrue(_fm(ozERC20.balanceOf(bob) + ozERC20.balanceOf(alice)) == _fm(ozERC20.totalSupply()));
        // assertTrue(ozBalanceAlicePostMock > ozERC20.balanceOf(alice));
        // assertTrue(ozERC20.balanceOf(alice) == 0 || ozERC20.balanceOf(alice) < 0.0000011 * 1e18);
        // assertTrue(balanceAliceTestTokenPreRedeem < IERC20Permit(testToken).balanceOf(alice));
        // assertTrue(deltaBalanceTestToken > 32 * decimals  && deltaBalanceTestToken <= 33 * decimals);

        return (amountIn, reth_usd_preAccrual);
    }


}