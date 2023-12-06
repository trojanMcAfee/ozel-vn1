// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {Setup} from "./Setup.sol";
import {BaseMethods} from "./BaseMethods.sol";
import {Type} from "./AppStorageTests.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "forge-std/console.sol";

import {TestMethods} from "./TestMethods.sol";


contract CoreTokenLogicRPtest is TestMethods {

    using FixedPointMathLib for uint;
    using HelpersLib for address;

    

    modifier confirmRethSupplyIncrease() {
        _modifyRocketPoolDepositMaxLimit();
        uint preSupply = IERC20Permit(rEthAddr).totalSupply();
        _;
        uint postSupply = IERC20Permit(rEthAddr).totalSupply();
        assertTrue(postSupply > preSupply);
    }


    //-----------------------


    function test_minting_approve_smallMint_rocketPool() public confirmRethSupplyIncrease {
        _minting_approve_smallMint();
    }

    function test_minting_approve_bigMint_rocketPool() public confirmRethSupplyIncrease {
        _minting_approve_bigMint();
    }

    function test_minting_eip2612_rocketPool() public confirmRethSupplyIncrease { 
        _minting_eip2612();
    } 

    function test_ozToken_supply_rocketPool() public confirmRethSupplyIncrease { 
        _ozToken_supply();
    } 

    function test_transfer_rocketPool() public confirmRethSupplyIncrease {
        _transfer();
    }

    function test_redeeming_bigBalance_bigMint_bigRedeem_rocketPool() public confirmRethSupplyIncrease {
       _redeeming_bigBalance_bigMint_bigRedeem();
    }

    function test_redeeming_bigBalance_smallMint_smallRedeem_rocketPool() public confirmRethSupplyIncrease {
       _redeeming_bigBalance_smallMint_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_smallRedeem_rocketPool() public confirmRethSupplyIncrease {
       _redeeming_bigBalance_bigMint_smallRedeem();
    }

    function test_redeeming_multipleBigBalances_bigMints_smallRedeem_rocketPool() public confirmRethSupplyIncrease {
       _redeeming_multipleBigBalances_bigMints_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_mediumRedeem_rocketPool() public confirmRethSupplyIncrease {
        _redeeming_bigBalance_bigMint_mediumRedeem();
    }

    function test_redeeming_eip2612_rocketPool() public confirmRethSupplyIncrease {
        _redeeming_eip2612();
    }

    function test_redeeming_multipleBigBalances_bigMint_mediumRedeem_rocketPool() public confirmRethSupplyIncrease {
        _redeeming_multipleBigBalances_bigMint_mediumRedeem();
    }

}