// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "./../../../../../../contracts/Errors.sol";

import {console} from "forge-std/console.sol";


contract Mint_Core is SharedConditions {

    function it_should_revert(uint decimals_) internal {
        //Pre-conditions
        assertEq(IERC20(testToken_internal).decimals(), decimals_);

        uint amountIn = 0;

        //Action
        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(), 
            alice
        );

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(OZError37.selector)
        );
        ozERC20.mint(data, alice);
    }

}