// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";
import {AmountsIn} from "./../../../../../../contracts/AppStorage.sol";
import "./../../../../../../contracts/Errors.sol";

import {console} from "forge-std/console.sol";


contract Mint_Core is SharedConditions {

    enum Revert {
        OWNER,
        AMOUNT_IN,
        RECEIVER
    }

    function it_should_revert(uint decimals_, Revert type_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        address owner = alice;
        address receiver = alice;
        bytes4 selector;

        if (type_ == Revert.AMOUNT_IN) {
            amountIn = 0;
            selector = OZError37.selector;
        } else if (type_ == Revert.OWNER) {
            owner = address(0);
            selector = OZError38.selector;
        } else if (type_ == Revert.RECEIVER) {
            receiver = address(0);
            selector = OZError38.selector;
        }

        //Actions + Post-conditions
        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(), 
            receiver
        );

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(selector)
        );
        ozERC20.mint(data, owner);
    }

    //so far, not used
    function it_should_mint(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);
        
        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        bytes memory data = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice);

        vm.startPrank(alice);
        IERC20(underlying).approve(address(OZ), amountIn);
        ozERC20.mint(data, alice);

        uint decimals_internal = decimals_ == 6 ? 1e12 : 1;

        assertTrue(
            _checkPercentageDiff(amountIn * decimals_internal, ozERC20.balanceOf(alice), 2)
        );
    }

    function it_should_throw_error(uint decimals_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        uint[] memory minAmountsOut = new uint[](3);
        for (uint i=0; i < minAmountsOut.length; i++) {
            minAmountsOut[i] = type(uint).max;
        }

        AmountsIn memory amts = AmountsIn(amountIn, minAmountsOut);

        bytes memory data = abi.encode(amts, alice);

        vm.startPrank(alice);
        IERC20(underlying).approve(address(OZ), amountIn);

        vm.expectRevert(
            abi.encodeWithSelector(OZError39.selector, data)
        );
        ozERC20.mint(data, alice);
    }
    
}