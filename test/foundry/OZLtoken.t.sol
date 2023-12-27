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

        // ozIToken ozERC20 = ozIToken(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac);

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
        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        //------- OZL fee ------ ****
        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(!wasCharged);
        //------- OZL fee ------ ****

        //BOB
        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        console.log('under: ', OZ.getUnderlyingValue());
        console.log('totalAssets: ', ozERC20.totalAssets());

        //--------
        uint rETHrate = IRocketTokenRETH(rEthAddr).getExchangeRate();
        console.log('rETHrate - premock: ', rETHrate);

        // uint rETHrateMock = 1097152127893442928;
        // vm.mockCall( 
        //     address(rEthAddr),
        //     abi.encodeWithSignature('getExchangeRate()'),
        //     abi.encode(rETHrateMock)
        // );    

        // int ETHRateMock = 169283007425;
        // vm.mockCall( 
        //     address(ethUsdChainlink),
        //     abi.encodeWithSignature('latestRoundData()'),
        //     abi.encode(uint80(0), ETHRateMock, uint(0), uint(0), uint80(0))
        // ); 

        int rETHETHmock = 1096480787660134800;
        vm.mockCall( 
            address(rEthEthChainlink),
            abi.encodeWithSignature('latestRoundData()'),
            abi.encode(uint80(0), rETHETHmock, uint(0), uint(0), uint80(0))
        ); 



        //--------

        //Charges fee
        wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        uint ozlRethBalance = IOZL(address(ozlProxy)).getBal(); //<---- here ****
        // assertTrue(pass);

        console.log('--');
     
        uint pastCalculatedRewardsETH = OZ.getLastRewards().prevTotalRewards;
        console.log('totalRewards in test: ', pastCalculatedRewardsETH);
        uint ozelFeesETH = OZ.getProtocolFee().mulDivDown(pastCalculatedRewardsETH, 10_000);
        console.log('ozelFeesETH ***: ', ozelFeesETH);

        // pastCalculatedRewardsETH --- 100%
        //      x -------------- fee

        // 1 rETH --- 1.08 ETH - rETH_ETH()
        //    x ------ ozelFeesETH

        uint ozelFeesRETH = ozelFeesETH.mulDivDown(1 ether, OZ.rETH_ETH());
        assertTrue(ozlRethBalance == ozelFeesRETH);

        // uint ozlFeesInReth = IERC20Permit(rEthAddr).balanceOf(address(ozlProxy));
        // uint ozlFeesUSDCalculated = (ozlFeesInReth * OZ.rETH_USD()) / 1 ether;
        // console.log('ozlFeesUSDCalculated: ', ozlFeesUSDCalculated);

        // uint feeDifference = ozelFeesUSD - ozlFeesUSDCalculated;
        // uint percentageDiff = feeDifference.mulDivDown(10_000, ozelFeesUSD);
        // console.log('percentageDiff: ', percentageDiff);



        //--------

        // amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        // _createAndMintOzTokens(
        //     address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        // );
        // _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
    }  



}