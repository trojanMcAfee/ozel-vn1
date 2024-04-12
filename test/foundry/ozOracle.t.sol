// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "../../contracts/libraries/oracle/OracleLibrary.sol";
import {IUsingTellor} from "../../contracts/interfaces/IUsingTellor.sol";
import {IRocketTokenRETH} from "../../contracts/interfaces/IRocketPool.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Dir} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";




contract ozOracleTest is TestMethods {


    //Makes a designated Chainlink feed fail the checks in the contract.
    function _mock_false_chainlink_feed(address feed_) internal {
        vm.mockCall(
            feed_,
            abi.encodeWithSignature('latestRoundData()'),
            abi.encode(uint80(0), int(0), uint(0), uint(0), uint80(0))
        );
    }

    //change this to be a test for getUniPrice(1, Dir.UP) after having modified
    // __callFallbackOracle() to use that as backup for rETH
    function test_medium_callFallbackOracle_rETHETH() public {
        if (_skip()) return;
        
        //Pre-condition
        _mock_false_chainlink_feed(rEthEthChainlink);
        //this ^ doesn't actually fail because rETH-ETH is no longer Chainlink, but 
        //TWAP. Make it fail for when getUniPrice deviates 1% from a reference (link feed)

        //Actions
        uint rate = OZ.rETH_ETH();
        uint protocolRate = IRocketTokenRETH(rEthAddr).getExchangeRate();

        //Post-condition
        assertTrue(rate == protocolRate);
    }

    
    function test_medium_callFallbackOracle_ETHUSD() public {
        //Pre-condtions
        vm.selectFork(redStoneFork);

        _mock_false_chainlink_feed(ethUsdChainlink);
    
        //Action
        uint ethPrice = OZ.ETH_USD();

        //Post-condition
        assertTrue(ethPrice == _getUniPrice());
    }


    function test_lastOption_uniPrice_callFallbackOracle_ETHUSD() public {
        //Pre-condtions
        vm.selectFork(redStoneFork);

        _mock_false_chainlink_feed(ethUsdChainlink);
        _mock_false_chainlink_feed(weETHETHredStone);

        //Action
        uint ethPrice = OZ.ETH_USD();

        //Post-condition
        assertTrue(ethPrice == _getUniPrice());
    }

    
    //Tests that when the deviation check in rETH-ETH fails, _callFallbackOracle() is
    //called an a price for rETH-ETH is given without interruptions.

    //add the changes to all mocks and forge test again
    function test_failed_deviation() public {
        //Pre-conditions
        vm.selectFork(redStoneFork);
        _mock_false_chainlink_feed(ethUsdChainlink);

        //Action
        _redeeming_bigBalance_bigMint_bigRedeem();

        //Post-conditions
        uint uni01Reth = OZ.getUniPrice(1, Dir.UP);
        uint protocolReth = IRocketTokenRETH(rEthAddr).getExchangeRate();
        uint backupReth = OZ.rETH_ETH();

        assertTrue(backupReth == (uni01Reth + protocolReth) / 2);
    }






}




