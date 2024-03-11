// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";

import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


contract BalancerPathTest is TestMethods {

    using FixedPointMathLib for uint;

    function test_z() public {
        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        _getResetVarsAndChangeSlip();

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false); 

        _mintOzTokens(ozERC20, alice, testToken, rawAmount * 10 ** IERC20Permit(testToken).decimals());

        uint ozBalAlicePre = ozERC20.balanceOf(alice);
        console.log('ozBalAlicePre: ', ozBalAlicePre);

        bytes memory redeemDataAlice = OZ.getRedeemData(
            ozBalAlicePre,
            address(ozERC20),
            OZ.getDefaultSlippage(),
            alice
        );

        uint testBalanceAlicePre = IERC20Permit(testToken).balanceOf(alice);
        console.log('testBalanceAlicePre: ', testBalanceAlicePre);

        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozBalAlicePre);
        uint assetsOutAlice = ozERC20.redeem(redeemDataAlice, alice); 
        vm.stopPrank();

        testBalanceAlicePre = IERC20Permit(testToken).balanceOf(alice);
        console.log('testBalanceAlicePost: ', testBalanceAlicePre);
    }

   
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