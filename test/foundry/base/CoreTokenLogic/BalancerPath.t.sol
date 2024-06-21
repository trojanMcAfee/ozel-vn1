// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../TestMethods.sol";
import {FixedPointMathLib} from "../../../../contracts/libraries/FixedPointMathLib.sol";

//--------
import {IERC20Permit} from "./../../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "./../../../../contracts/interfaces/ozIToken.sol";
import {IAave} from "./../../../../contracts/interfaces/IAave.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AmountsIn} from "./../../../../contracts/AppStorage.sol";


import "forge-std/console.sol";


contract BalancerPathTest is TestMethods {

    using FixedPointMathLib for uint;


    function test_strategy_new() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();   
        console.log('amountInStable in test: ', amountIn);

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        bytes memory mintData = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice, address(ozERC20));
        (AmountsIn memory amts,) = abi.decode(mintData, (AmountsIn, address));

        payable(alice).transfer(1000 ether);

        vm.startPrank(alice);

        IERC20(testToken).approve(address(OZ), amountIn);
        ozERC20.mint2{value: amts.amountInETH}(mintData, alice, true);

        vm.stopPrank();

        bool success = OZ.executeRebaseSwap();
        console.log('success - true: ', success);

        // console.log('oz bal alice: ', ozERC20.balanceOf(alice));
    }

   
   //------------
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