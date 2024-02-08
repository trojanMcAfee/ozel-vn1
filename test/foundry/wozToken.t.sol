    // SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {wozIToken} from "../../contracts/interfaces/wozIToken.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {NewToken} from "../../contracts/AppStorage.sol";
import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC4626Upgradeable.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";

import "forge-std/console.sol";


contract wozTokenTest is TestMethods {

    function test_x() public {

        (ozIToken ozERC20, wozIToken wozERC20) = _createOzTokens(testToken, "1");
        // wozERC20.getHello();

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        _mintOzTokens(ozERC20, alice, testToken, amountIn); 

        uint ozBalancePre = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePre > 0);
        console.log('ozBalancePre - not 0: ', ozBalancePre);

        uint wozBalancePre = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePre == 0);
        console.log('wozBalancePre - 0: ', wozBalancePre);

        address underlying = wozERC20.asset();
        assertTrue(underlying == address(ozERC20));

        vm.startPrank(alice);
        ozERC20.approve(address(wozERC20), ozBalancePre);
        uint shares = wozERC20.deposit(ozBalancePre, alice);
        assertTrue(shares > 0);

        uint wozBalancePost = wozERC20.balanceOf(alice);
        assertTrue(wozBalancePost > 0);
        console.log('wozBalancePost - not 0: ', wozBalancePost);

        uint ozBalancePost = ozERC20.balanceOf(alice);
        assertTrue(ozBalancePost == 0);
        console.log('ozBalancePost - 0: ', ozBalancePost);

        vm.stopPrank();

    }

    // ozBalancePre and wozBalancePost are identical. why??


}