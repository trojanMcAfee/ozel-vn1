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

    //One user deposits ozERC20 to mint wozERC20, and then withdraws them back for ozERC20
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

    //Two users mint wozERC20 from the same token
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

    //Continuation of the previos tests:
    //Two users redeem ozERC20 for wozERC20
    function test_redeem_twoUsers() public {
        //Pre-conditions
        (, wozIToken wozERC20) = test_mint_twoUsers();

        uint wozBalanceAlice = wozERC20.balanceOf(alice);
        uint wozBalanceBob = wozERC20.balanceOf(bob);

        assertTrue(wozBalanceAlice > 0);
        assertTrue(wozBalanceBob > 0);

        //Actions
        vm.startPrank(alice);
        wozERC20.approve(address(wozERC20), type(uint).max);
        wozERC20.redeem(
            wozERC20.convertToShares(wozBalanceAlice),
            alice,
            alice
        );
        vm.stopPrank();
        
        vm.startPrank(bob);
        wozERC20.approve(address(wozERC20), type(uint).max);
        wozERC20.redeem(
            wozERC20.convertToShares(wozBalanceBob),
            bob,
            bob
        );
        vm.stopPrank();

        //Post-conditions
        assertTrue(wozERC20.balanceOf(alice) == 0);
        assertTrue(wozERC20.balanceOf(bob) == 0);
    }


    function test_x() public {
        (bytes32 oldSlot0data, bytes32 oldSharedCash, bytes32 cashSlot) = _getResetVarsAndChangeSlip();

        //create ozToken
        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();

        //mint ozToken
        _mintOzTokens(ozERC20, alice, testToken, amountIn);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        _mintOzTokens(ozERC20, bob, testToken, amountIn); 

        uint ozBalanceAlice = ozERC20.balanceOf(alice);
        console.log('ozBalanceAlice: ', ozBalanceAlice);

        uint ozBalanceBob = ozERC20.balanceOf(bob);
        console.log('ozBalanceBob: ', ozBalanceBob);
        
        console.log(' ');
        console.log('*** mint wozERC20 ***');
        console.log(' ');

        vm.startPrank(alice);
        ozERC20.approve(address(wozERC20), ozBalanceAlice);
        uint x = wozERC20.wrap(ozBalanceAlice, alice); 
        vm.stopPrank();

        uint wozBalanceAlice = wozERC20.balanceOf(alice);
        console.log('wozBalanceAlice - pre accrual: ', wozBalanceAlice);

        ozBalanceAlice = ozERC20.balanceOf(alice); 
        console.log('ozBalanceAlice - post woz mint - should 0: ', ozBalanceAlice);

        console.log(' ');
        console.log('*** accrual ***');
        _accrueRewards(100);
        console.log(' ');

        ozBalanceBob = ozERC20.balanceOf(bob);
        console.log('ozBalanceBob - post accrual - should increase: ', ozBalanceBob);

        wozBalanceAlice = wozERC20.balanceOf(alice);
        console.log('wozBalanceAlice - post accrual - should remain: ', wozBalanceAlice);

        ozBalanceAlice = ozERC20.balanceOf(alice); 
        console.log('ozBalanceAlice - post accrual - should 0: ', ozBalanceAlice);        

        uint ozBalanceWoz = ozERC20.balanceOf(address(wozERC20));
        console.log('ozBalanceWoz: ', ozBalanceWoz);

        console.log(' ');
        console.log('*** redeem wozERC20 ***');
        console.log(' ');

        vm.prank(alice);
        // wozERC20.withdraw(wozBalanceAlice, alice, alice); 
        wozERC20.unwrap(wozBalanceAlice, alice, alice); 

        wozBalanceAlice = wozERC20.balanceOf(alice);
        console.log('wozBalanceAlice - post withdraw - should 0: ', wozBalanceAlice);
        
        ozBalanceAlice = ozERC20.balanceOf(alice);
        console.log('ozBalanceAlice - post withdraw - should bob: ', ozBalanceAlice);

        ozBalanceBob = ozERC20.balanceOf(bob);
        console.log('ozBalanceBob - post withdraw - should remain: ', ozBalanceBob);

        ozBalanceWoz = ozERC20.balanceOf(address(wozERC20));
        console.log('ozBalanceWoz - post withdrawl - should 0: ', ozBalanceWoz);
    }

    


}