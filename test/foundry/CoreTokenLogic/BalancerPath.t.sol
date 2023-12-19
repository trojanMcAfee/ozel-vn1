// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";

import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


contract BalancerPathTest is TestMethods {

    using FixedPointMathLib for uint;


    // function getFees() public {
    //     total

    // }


    function test_fees() public {
        _minting_approve_smallMint();

        ozIToken ozERC20 = ozIToken(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac);

        console.log('under: ', OZ.getUnderlyingValue());
        console.log('totalShares: ', ozERC20.totalShares());
        
        int numerator = int(OZ.getUnderlyingValue() * 1500 * ozERC20.totalShares());
        console.log(1);
        console.log('rETH bal: ', IERC20Permit(rEthAddr).balanceOf(address(OZ)));
        int denominator = int((IERC20Permit(rEthAddr).balanceOf(address(OZ)) * 10_000)) - int((1500 * OZ.getUnderlyingValue()));
        console.log(2);
        int sharesToMint = numerator / denominator;

        console.logInt(sharesToMint);
        console.log('sharesToMint ^^');

        // 100_000_000 ---- 100%
        //     x      ------ 15% x = 1_500_000
    }

    function applyFee(uint subTotal_) public pure returns(uint) {
        uint fee = 1_500;
        return fee.mulDivDown(subTotal_, 10_000);
    }

    function test_fees2() public {
        _minting_approve_smallMint();

        ozIToken ozERC20 = ozIToken(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac);

        uint val = OZ.getUnderlyingValue();
        console.log('UnderlyingValue: ', val);

        uint totalShares = ozERC20.totalShares();
        console.log('totalShares: ', totalShares);
        
        uint feeShares = applyFee(totalShares);
        console.log('feeShares: ', feeShares);

        uint assets = ozERC20.convertToAssets(feeShares);
        console.log('assets: ', assets);
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
            abi.encode(101 * 1e18)
        );

        underValue = OZ.getUnderlyingValue();
        console.log('mocked underValue: ', underValue);

        // uint netFees = OZ.getUnderlyingValue() - (ozERC20.totalAssets() * 1e12);
        // console.log('netFees: ', netFees);

    }



    //---------
   
    function test_minting_approve_smallMint_balancer() public {
        _minting_approve_smallMint();
    }

    function test_minting_approve_bigMint_balancer() public {
        _minting_approve_bigMint();
    }

    function test_minting_eip2612_balancer() public { 
        _minting_eip2612();
    }   

    function test_ozToken_supply_balancer() public {
        _ozToken_supply();
    }

    function test_transfer_balancer() public {
        _transfer();
    }

    function test_redeeming_bigBalance_bigMint_bigRedeem_balancer() public {
        _redeeming_bigBalance_bigMint_bigRedeem();
    }

    function test_redeeming_bigBalance_smallMint_smallRedeem_balancer() public {
        _redeeming_bigBalance_smallMint_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_smallRedeem_balancer() public {
        _redeeming_bigBalance_bigMint_smallRedeem();
    }

    function test_redeeming_multipleBigBalances_bigMints_smallRedeem_balancer() public {
        _redeeming_multipleBigBalances_bigMints_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_mediumRedeem_balancer() public {
        _redeeming_bigBalance_bigMint_mediumRedeem();
    }

    function test_redeeming_eip2612_balancer() public {
        _redeeming_eip2612();
    }

    function test_redeeming_multipleBigBalances_bigMint_mediumRedeem_balancer() public {
        _redeeming_multipleBigBalances_bigMint_mediumRedeem();
    }
}