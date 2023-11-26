// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;



import {Setup} from "./Setup.sol";



contract CoreTokenLogicRPtest is Setup {



    function test_minting_approve_smallMint_rocketPool() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _modifyRocketPoolDepositMaxLimit();

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }

}