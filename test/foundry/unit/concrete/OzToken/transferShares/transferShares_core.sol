// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";


contract TransferShares_Core is SharedConditions {

    function it_should_transfer_shares(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();

        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(),
            alice
        );

        vm.startPrank(alice);
        IERC20(underlying).approve(address(OZ), amountIn);
        uint sharesOut = ozERC20.mint(data, alice);

        assertEq(sharesOut, ozERC20.sharesOf(alice));

        uint ozBalanceAlicePreTransfer = ozERC20.balanceOf(alice);
        uint ozBalanceBobPreTransfer = ozERC20.balanceOf(bob);
        assertEq(ozBalanceBobPreTransfer, 0);

        //Action
        uint ozBalanceOut = ozERC20.transferShares(bob, sharesOut);

        //Post-conditions
        uint ozBalanceBobPostTransfer = ozERC20.balanceOf(bob);
        uint ozBalanceAlicePostTransfer = ozERC20.balanceOf(alice);

        assertEq(ozBalanceAlicePreTransfer, ozBalanceOut);
        assertEq(ozBalanceAlicePreTransfer, ozBalanceBobPostTransfer);
        assertEq(ozBalanceAlicePostTransfer, 0);
    }


}