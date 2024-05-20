// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../SharedConditions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ozIToken} from "./../../../../../../contracts/interfaces/ozIToken.sol";
import {IMockRocketPoolStorage} from "./../../../../../../contracts/interfaces/IRocketPool.sol";
import {AmountsIn} from "./../../../../../../contracts/AppStorage.sol";
import "./../../../../../../contracts/Errors.sol";
import {MockReentrantRocketVault} from "../../../../mocks/rocket-pool/MockRocketVault.sol";

import {console} from "forge-std/console.sol";


contract Mint_Core is SharedConditions {

    enum Revert {
        OWNER,
        AMOUNT_IN,
        RECEIVER,
        REENTRANT
    }

    function it_should_revert(uint decimals_, Revert type_) internal {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
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
        } else if (type_ == Revert.REENTRANT) {
            MockReentrantRocketVault reentrantVault = new MockReentrantRocketVault(ozERC20);

            address mockRocketVault = IMockRocketPoolStorage(rocketPoolStorage).vault();
            vm.etch(mockRocketVault, address(reentrantVault).code);

            selector = OZError40.selector;
        }

        //Actions + Post-conditions
        bytes memory data = OZ.getMintData(
            amountIn,
            OZ.getDefaultSlippage(), 
            receiver
        );

        vm.startPrank(alice);
        IERC20(underlying).approve(address(OZ), amountIn);

        vm.expectRevert(
            abi.encodeWithSelector(selector)
        );
        ozERC20.mint(data, owner);
    }


    function it_should_mint(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
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

    function it_should_throw_error_39(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
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

        //Action + post-condition
        vm.expectRevert(
            abi.encodeWithSelector(OZError39.selector, data)
        );
        ozERC20.mint(data, alice);
    }


    function it_should_throw_error_22(uint decimals_) internal skipOrNot {
        //Pre-conditions
        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals_);
        assertEq(IERC20(underlying).decimals(), decimals_);

        uint underlyingBalanceAlice = IERC20(underlying).balanceOf(alice);
        assertGt(underlyingBalanceAlice, 0);

        vm.startPrank(alice);
        IERC20(underlying).transfer(address(1), underlyingBalanceAlice);

        assertEq(IERC20(underlying).balanceOf(alice), 0);
        
        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        bytes memory data = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice);

        //Action + Post-condtion
        IERC20(underlying).approve(address(OZ), amountIn);

        vm.expectRevert(
            abi.encodeWithSelector(OZError22.selector, "ERC20: transfer amount exceeds balance")
        );
        ozERC20.mint(data, alice);
    }
    
}