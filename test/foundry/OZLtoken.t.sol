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
        uint bpsIncrease = 400; //92 - 400
        uint rETHETHmock = OZ.rETH_ETH() + bpsIncrease.mulDivDown(OZ.rETH_ETH(), 10_000);

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

    // function test_exchangeRate_no_circulatingSupply


    function test_exchangeRate_with_circulatingSupply() public {
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        _startCampaign();
        _mintOzTokens(ozERC20, alice, amountIn); 

        uint secs = 10;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        vm.prank(alice);
        OZ.claimReward();

        //-----
        IOZL OZL = IOZL(address(ozlProxy));

        uint rate = OZL.getExchangeRate();
        console.log('rate3: ', rate);
        //-----

        uint ozlBal = OZL.balanceOf(alice);
        console.log('ozlBal alice: ', ozlBal);

        uint ozlRedeem = (rate * ozlBal) / 1 ether;
        console.log('ozlRedeem in USD: ', ozlRedeem);


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
        _mintOzTokens(ozERC20, bob, amountIn);

        _mock_rETH_ETH();

        //Charges fee
        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlRethBalance = OZL.getBal(); 

        /**
         * Post-conditions
         */
        uint pastCalculatedRewardsETH = OZ.getLastRewards().prevTotalRewards; 
        uint ozelFeesETH = OZ.getProtocolFee().mulDivDown(pastCalculatedRewardsETH, 10_000);
        uint netOzelFeesETH = ozelFeesETH - uint(50).mulDivDown(ozelFeesETH, 10_000);

        uint ozelFeesRETH = netOzelFeesETH.mulDivDown(1 ether, OZ.rETH_ETH());
        uint feesDiff = ozlRethBalance - ozelFeesRETH;
        assertTrue(feesDiff <= 1 && feesDiff >= 0);

        uint ownerBalance = IERC20Permit(rEthAddr).balanceOf(owner);
        assertTrue(ownerBalance > 0);

        vm.clearMockedCalls();
    }  





    //---------

    //** this function represents the notes in chargeOZLfee() (will fail) */
    function test_exchangeRate_edge_case() internal {
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        _startCampaign();
        _mintOzTokens(ozERC20, alice, amountIn); 

        uint secs = 10;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        _dealUnderlying(Quantity.BIG);
        _mintOzTokens(ozERC20, alice, amountIn); //<-- part the makes this function fail

        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        vm.prank(alice);
        OZ.claimReward();

        //-----
        IOZL OZL = IOZL(address(ozlProxy));

        uint rate = OZL.getExchangeRate();
        console.log('rate3: ', rate);
    }
}