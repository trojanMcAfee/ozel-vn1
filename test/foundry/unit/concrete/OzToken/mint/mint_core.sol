// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";
import "./../../../../../../contracts/Errors.sol";

import {console} from "forge-std/console.sol";


contract Mint_Core is SharedConditions {

    enum Revert {
        OWNER,
        AMOUNT_IN
    }

    function it_should_revert(uint decimals_, Revert type_) internal {
        //Pre-conditions
        ozIToken ozERC20 = setUpOzToken(decimals_);
        address underlying = ozERC20.asset();
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn;
        address owner;
        bytes4 selector;

        if (type_ == Revert.AMOUNT_IN) {
            amountIn = 0;
            owner = alice;
            selector = OZError37.selector;
        } else if (type_ == Revert.OWNER) {
            amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
            owner = address(0);
            selector = OZError38.selector;
        }

        //Action
        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(), 
            alice
        );

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(selector)
        );
        ozERC20.mint(data, owner);
    }

}