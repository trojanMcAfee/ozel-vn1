// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";

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

        ozIToken ozERC20 = ozIToken(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac);

        uint totalAssets = ozERC20.totalAssets();
        console.log('totalAssets: ', totalAssets);

        uint underValue = OZ.getUnderlyingValue();
        console.log('underValue: ', underValue);
        //------

        vm.mockCall(
            address(OZ),
            abi.encodeWithSignature('getUnderlyingValue()'),
            abi.encode(110 * 1e18)
        );

        underValue = OZ.getUnderlyingValue();
        console.log('mocked underValue: ', underValue);

        // uint netFees = OZ.getUnderlyingValue() - (ozERC20.totalAssets() * 1e12);
        // console.log('netFees: ', netFees);

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


}