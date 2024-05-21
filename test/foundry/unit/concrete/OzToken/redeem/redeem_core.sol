// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";

import {console} from "forge-std/console.sol";


contract Redeem_Core is SharedConditions {

    function it_should_revert(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        _mintOzTokens(ozERC20, alice, underlying, amountIn);
        // _mintOzTokens(ozERC20, bob, underlying, amountIn);
        
        uint ozAmountIn = ozERC20.balanceOf(alice);

        bytes memory data = OZ.getRedeemData(
            ozAmountIn, 
            address(ozERC20), 
            OZ.getDefaultSlippage(), 
            alice, 
            alice
        );

        vm.startPrank(alice);
        ozERC20.approve(address(OZ), ozAmountIn);
        console.log(2);
        ozERC20.redeem(data, alice);
        console.log(3);
    }

}