// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";

import "forge-std/console.sol";


contract PausedPathTest is TestMethods {


    function test_minting_approve_smallMint_paused() public pauseBalancerPool {
        _minting_approve_smallMint();
    }

    function test_minting_approve_bigMint_paused() public pauseBalancerPool {
        _minting_approve_bigMint();
    }

    function test_minting_eip2612_paused() public pauseBalancerPool { 
        _minting_eip2612();
    }   

    function test_ozToken_supply_paused() public pauseBalancerPool {
        _ozToken_supply();
    }

    function test_transfer_paused() public pauseBalancerPool {
        _transfer();
    }

    function test_redeeming_bigBalance_bigMint_bigRedeem_paused() public pauseBalancerPool {
        _redeeming_bigBalance_bigMint_bigRedeem();
    }

    function test_redeeming_bigBalance_smallMint_smallRedeem_paused() public pauseBalancerPool {
        _redeeming_bigBalance_smallMint_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_smallRedeem_paused() public rollBlockAndState pauseBalancerPool {
        _redeeming_bigBalance_bigMint_smallRedeem();
    }

    function test_redeeming_multipleBigBalances_bigMints_smallRedeem_paused() public pauseBalancerPool {
        _redeeming_multipleBigBalances_bigMints_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_mediumRedeem_paused() public pauseBalancerPool {
        _redeeming_bigBalance_bigMint_mediumRedeem();
    }

    function test_redeeming_eip2612_paused() public pauseBalancerPool {
        _redeeming_eip2612();
    }

    function test_redeeming_multipleBigBalances_bigMint_mediumRedeem_paused() public rollBlockAndState pauseBalancerPool {
        _redeeming_multipleBigBalances_bigMint_mediumRedeem();
    }
}