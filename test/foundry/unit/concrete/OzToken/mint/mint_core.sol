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
        assertEq(IERC20(ozERC20.asset()).decimals(), decimals_);

        uint amountIn;
        address owner;

        if (type_ == Revert.AMOUNT_IN) {
            amountIn = 0;
            owner = alice;
        }

        //Action
        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(), 
            owner
        );

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(OZError37.selector)
        );
        ozERC20.mint(data, alice);
    }

}