// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Type} from "./AppStorageTests.sol";
import {IRocketTokenRETH} from "../../contracts/interfaces/IRocketPool.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "forge-std/console.sol";


contract OZLtokenTest is TestMethods {

    using FixedPointMathLib for uint;


   function _mock_rETH_ETH() internal {
        uint bspIncrease = 92;
        uint rETHETHmock = OZ.rETH_ETH() + bspIncrease.mulDivDown(OZ.rETH_ETH(), 10_000);

        vm.mockCall( 
            address(rEthEthChainlink),
            abi.encodeWithSignature('latestRoundData()'),
            abi.encode(uint80(0), int(rETHETHmock), uint(0), uint(0), uint80(0))
        ); 
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
         * Pre-conditions
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
        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        //BOB
        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);


        //--------
        _mock_rETH_ETH();

        //--------

        //Charges fee
        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        uint ozlRethBalance = IOZL(address(ozlProxy)).getBal(); 

        /**
         * Post-conditions
         */
        uint pastCalculatedRewardsETH = OZ.getLastRewards().prevTotalRewards;
        uint ozelFeesETH = OZ.getProtocolFee().mulDivDown(pastCalculatedRewardsETH, 10_000);

        uint ozelFeesRETH = ozelFeesETH.mulDivDown(1 ether, OZ.rETH_ETH());
        assertTrue(ozlRethBalance == ozelFeesRETH);


        //--------

        // amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        // _createAndMintOzTokens(
        //     address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        // );
        // _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        vm.clearMockedCalls();
    }  

}