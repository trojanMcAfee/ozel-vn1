// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Type} from "./AppStorageTests.sol";

import "forge-std/console.sol";


contract OZLtokenTest is TestMethods {

    using FixedPointMathLib for uint;


    function test_token() public {

        IOZL ozl = IOZL(OZ.getOZL());
        ozl.getRewards();
    }

    function applyFee(uint subTotal_) public pure returns(uint) {
        uint fee = 1_500;
        return fee.mulDivDown(subTotal_, 10_000);
    }


    function test_fees3() public {
        _minting_approve_smallMint();

        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(!wasCharged);

        ozIToken ozERC20 = ozIToken(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac);

        // uint totalAssets = ozERC20.totalAssets();
        // console.log('totalAssets: ', totalAssets);

        // uint underValue = OZ.getUnderlyingValue();
        // console.log('underValue: ', underValue);
        //------

        vm.mockCall(
            address(OZ),
            abi.encodeWithSignature('getUnderlyingValue()'),
            abi.encode(110 * 1e18)
        );

        uint underValue = OZ.getUnderlyingValue();
        console.log('mocked underValue: ', underValue);



    }

    //-------

    function test_chargeOZLfee_noFeesToDistribute() public {
        //Pre-condtion
        _minting_approve_smallMint();

        //Action
        bool wasCharged = OZ.chargeOZLfee();

        //Post-condition
        assertTrue(!wasCharged);
    }


    function test_chargeOZLfee_distributeFees() public { 
        /**
         * Pre-conditions + Actions (creating of ozTokens)
         */
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);

        /**
         * Actions
         */

         //ALICE
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        //------- OZL fee ------ ****
        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(!wasCharged);
        //------- OZL fee ------ ****

        //BOB
        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesBob) = _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        console.log('under: ', OZ.getUnderlyingValue());
        console.log('totalAssets: ', ozERC20.totalAssets());

        // vm.mockCall(
        //     address(OZ),
        //     abi.encodeWithSignature('getUnderlyingValue()'),
        //     abi.encode(110 * 1e18)
        // );
        // assertTrue(OZ.getUnderlyingValue(), 110 * 1e18);

        // wasCharged = OZ.chargeOZLfee();








        amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
    }  


}