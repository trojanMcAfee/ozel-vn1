// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {wozIToken} from "../../contracts/interfaces/wozIToken.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {NewToken} from "../../contracts/AppStorage.sol";
import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC4626Upgradeable.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "forge-std/console.sol";


contract wozTokenTest is TestMethods {

    function _getResetVarsAndChangeSlip() internal returns(bytes32, bytes32, bytes32) {
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();
        
        _changeSlippage(uint16(9900));

        return (oldSlot0data, oldSharedCash, cashSlot);
    }


    function test_deposit_withdraw_oneUser() public { 
        //Pre-conditions
        (bytes32 oldSlot0data, bytes32 oldSharedCash, bytes32 cashSlot) = _getResetVarsAndChangeSlip();

        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        _mintOzTokens(ozERC20, alice, testToken, amountIn); 
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        uint ozBalancePre = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePre > 0);

        uint wozBalancePre = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePre == 0);

        address underlying = wozERC20.asset();
        assertTrue(underlying == address(ozERC20));

        //Actions
        vm.startPrank(alice);

        ozERC20.approve(address(wozERC20), ozBalancePre);
        uint shares = wozERC20.deposit(ozBalancePre, alice);
        assertTrue(shares > 0);

        uint wozBalancePost = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePost > 0);

        uint ozBalancePost = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePost == 0);

        wozERC20.withdraw(wozBalancePost, alice, alice);
        uint wozBalancePostWithdrawal = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePostWithdrawal == 0);

        //Post-condition
        uint ozBalancePostWithdrawal = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePostWithdrawal > 0);

        vm.stopPrank();
    }


    function test_mint_twoUsers() public returns(ozIToken, wozIToken) {
        //Pre-condtions
        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        _mintOzTokens(ozERC20, alice, testToken, amountIn); 
        _mintOzTokens(ozERC20, bob, testToken, amountIn); 

        uint ozBalanceBob = ozERC20.balanceOf(bob);
        assertTrue(ozBalanceBob > 0);

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        assertTrue(ozBalanceAlice > 0);

        //Actions
        uint wozSharesBob = wozERC20.convertToShares(ozBalanceBob);

        vm.startPrank(bob);
        ozERC20.approve(address(wozERC20), ozBalanceBob);
        wozERC20.mint(wozSharesBob, bob);
        vm.stopPrank();

        uint wozSharesAlice = wozERC20.convertToShares(ozBalanceAlice);

        vm.startPrank(alice);
        ozERC20.approve(address(wozERC20), ozBalanceAlice);
        wozERC20.mint(wozSharesAlice, alice);
        vm.stopPrank();
        
        //Post-conditions
        uint wozBalanceBob = wozERC20.balanceOf(bob);
        assertTrue(wozBalanceBob > 0);

        uint wozBalanceAice = wozERC20.balanceOf(alice);
        assertTrue(wozBalanceAice > 0);

        assertTrue(wozBalanceAice == wozBalanceBob);

        return (ozERC20, wozERC20);
    }


    function test_redeem_twoUsers() public {
        //Pre-conditions
        (ozIToken ozERC20, wozIToken wozERC20) = test_mint_twoUsers();

        uint wozBalanceAlice = wozERC20.balanceOf(alice);
        uint wozBalanceBob = wozERC20.balanceOf(bob);

        assertTrue(wozBalanceAlice > 0);
        assertTrue(wozBalanceBob > 0);

        //Actions
        vm.prank(alice);
        wozERC20.redeem( //<--- check why this fails 
            wozERC20.convertToShares(wozBalanceAlice),
            alice,
            alice
        );
        
        vm.prank(bob);
        wozERC20.redeem(
            wozERC20.convertToShares(wozBalanceBob),
            bob,
            bob
        );

        //Post-conditions
        assertTrue(wozERC20.balanceOf(alice) == 0);
        assertTrue(wozERC20.balanceOf(bob) == 0);
    }

    function test_x() public {
        //create ozToken
        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        //mint ozToken
        _mintOzTokens(ozERC20, alice, testToken, amountIn); 

        uint ozBalancePre = ozERC20.balanceOf(alice);
        console.log('ozBalancePre: ', ozBalancePre);

        ozERC20.approve(address(wozERC20), ozBalancePre);
        wozERC20.deposit(ozBalancePre, alice);

        //avance the block numbers and prove that ozERC20 appreciates in value, 
        //while wozERC20 stays stable
    }

    


}