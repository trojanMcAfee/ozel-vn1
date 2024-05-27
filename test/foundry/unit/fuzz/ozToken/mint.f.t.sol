// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {SharedConditions} from "../../concrete/OzToken/SharedConditions.sol";
import {ozIToken} from "./../../../../../contracts/interfaces/ozIToken.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AmountsIn} from "./../../../../../contracts/AppStorage.sol";

import {console} from "forge-std/console.sol";


contract Mint_Unit_Fuzz_tes is SharedConditions {

    function testFuzz_RevertsWhen_data_is_evil(uint amountIn_, uint16 slippage_, address receiver_) public {
        vm.skip(true);
        
        vm.assume(amountIn_ != 0);
        vm.assume(slippage_ != 0);
        vm.assume(receiver_ != address(0));
        // data = bound(data.length, 224, 224);

        uint decimals = 18;

        (ozIToken ozERC20, address underlying) = _setUpOzToken(decimals);
        assertEq(IERC20(underlying).decimals(), decimals);

        uint amountIn = (rawAmount / 3) * 10 ** IERC20(underlying).decimals();
        _mintOzTokens(ozERC20, alice, underlying, amountIn);

        assertTrue(_checkPercentageDiff(amountIn, ozERC20.balanceOf(alice), 2));
        console.log(4);
        //------

        bytes memory evilData = OZ.getMintData(amountIn_, slippage_, receiver_);
        console.log(5);

        IERC20(underlying).approve(address(OZ), amountIn_);

        console.log(6);

        vm.expectRevert();
        ozERC20.mint(evilData, receiver_);

        console.log(7);

        assertEq(ozERC20.balanceOf(alice) + ozERC20.balanceOf(bob), ozERC20.totalSupply());
    }

}