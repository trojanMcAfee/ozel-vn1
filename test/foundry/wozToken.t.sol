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


    function test_deposit_oneUser_wozERC20() public { 
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

        //Action 1
        vm.startPrank(alice);

        ozERC20.approve(address(wozERC20), ozBalancePre);
        uint shares = wozERC20.deposit(ozBalancePre, alice);
        assertTrue(shares > 0);

        uint wozBalancePost = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePost > 0);

        uint ozBalancePost = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePost == 0);

        //Action 2
        wozERC20.withdraw(wozBalancePost, alice, alice);
        uint wozBalancePostWithdrawal = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePostWithdrawal == 0);

        uint ozBalancePostWithdrawal = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePostWithdrawal > 0);

        vm.stopPrank();
    }


    // function test_x() public {
    //     console.log('** start new test **');

    //     bytes32 oldSlot0data = vm.load(
    //         IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
    //         bytes32(0)
    //     );
    //     (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();
    //     //--------------

    //     (ozIToken ozERC20, wozIToken wozERC20, uint rawAmount) = 
    //         test_deposit_oneUser_wozERC20();

    //     uint amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();

    //     _mintOzTokens(ozERC20, bob, testToken, amountIn); 
    //     _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

    //     uint ozBalanceBob = ozERC20.balanceOf(bob);
    //     console.log('ozBalanceBob: ', ozBalanceBob);

    //     vm.startPrank(bob);

    //     ozERC20.approve(address(wozERC20), ozBalanceBob);
    //     wozERC20.deposit(ozBalanceBob, bob);

    //     vm.stopPrank();

    //     uint wozBalanceBob = wozERC20.balanceOf(bob);
    //     console.log('wozBalanceBob: ', wozBalanceBob);

    //     uint wozBalanceAice = wozERC20.balanceOf(alice);
    //     console.log('wozBalanceAice: ', wozBalanceAice);

    //     //---------
    //     // console.log('*** charlie part ***');

    //     // _mintOzTokens(ozERC20, charlie, testToken, amountIn); 

    //     // uint ozBalanceCharlie = ozERC20.balanceOf(charlie);
    //     // console.log('ozBalanceCharlie: ', ozBalanceCharlie);

    //     // vm.startPrank(charlie);

    //     // ozERC20.approve(address(wozERC20), ozBalanceCharlie);
    //     // wozERC20.deposit(ozBalanceCharlie, charlie);

    //     // vm.stopPrank();

    //     // uint wozBalanceCharlie = wozERC20.balanceOf(charlie);
    //     // console.log('wozBalanceCharlie: ', wozBalanceCharlie);
    // }

    


}