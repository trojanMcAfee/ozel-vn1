// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import "../../contracts/Errors.sol";
import {HelpersLib} from "./HelpersLib.sol";

import "forge-std/console.sol";


contract ozTokenTest is TestMethods {

    function test_catch_internal_errors_mint() public {
        //Pre-conditions  
        ozIToken ozERC20_1 = ozIToken(OZ.createOzToken(
            usdtAddr, "Ozel-ERC20-1", "ozERC20_1"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        vm.expectRevert(
            abi.encodeWithSelector(OZError22.selector, 'SafeERC20: low-level call failed')
        );

        // _mintOzTokens(ozERC20_1, alice, testToken, amountIn);

        (bytes memory data) = _createDataOffchain(
            ozERC20_1, amountIn_, ALICE_PK, alice, testToken, Type.IN
        );

        (uint[] memory minAmountsOut,,,) = HelpersLib.extract(data);

        vm.startPrank(user_);
        IERC20(token_).safeApprove(address(OZ), amountIn_);

        AmountsIn memory amounts = AmountsIn(
            amountIn_,
            minAmountsOut
        );

        vm.expectRevert(
            abi.encodeWithSelector(OZError22.selector, 'SafeERC20: low-level call failed')
        );

        ozERC20_.mint(abi.encode(amounts, user_));         
        vm.stopPrank();

    }

    //^^^ fix the terminal errors of this test


}