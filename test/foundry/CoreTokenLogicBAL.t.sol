// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {AmountsIn, AmountsOut, Asset} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract CoreTokenLogicBALtest is TestMethods {

    function test_under() public {
        _minting_approve_smallMint();

        uint totalrETH = OZ.totalUnderlying(Asset.UNDERLYING);
        uint totalUSD = OZ.totalUnderlying(Asset.USD);
        uint rEthEth = OZ.rETH_ETH();
        uint ethUsd = OZ.ETH_USD();

        console.log('totalrETH: ', totalrETH);
        console.log('totalUSD: ', totalUSD);
        console.log('rEthEth: ', rEthEth);
        console.log('ethUsd: ', ethUsd);
    }


    function test_minting_approve_smallMint_balancer() internal {
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