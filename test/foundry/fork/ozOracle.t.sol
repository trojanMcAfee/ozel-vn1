// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../base/TestMethods.sol";
import {IRocketTokenRETH} from "../../../contracts/interfaces/IRocketPool.sol";
import {Dir} from "../../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract ozOracleTest is TestMethods {


    //change this to be a test for getUniPrice(1, Dir.UP) after having modified
    // __callFallbackOracle() to use that as backup for rETH
    function test_medium_callFallbackOracle_rETHETH() skipOrNot public {
        // if (_skip()) return;
        
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

    
    /**
    * Tests that when the deviation check in rETH-ETH fails due to success being false,
    * _callFallbackOracle() is called an a price for rETH-ETH is given without interruptions.
    */
    function test_failed_false_deviation() public {
        //Pre-conditions
        vm.selectFork(redStoneFork);
        _mock_false_chainlink_feed(rEthEthChainlink);

        //Action
        _redeeming_bigBalance_bigMint_bigRedeem();

        //Post-condition
        uint uni01Reth = OZ.getUniPrice(1, Dir.UP) / 1e9;
        uint protocolReth = IRocketTokenRETH(rEthAddr).getExchangeRate();
        uint backupReth = OZ.rETH_ETH();

        assertTrue(backupReth == (uni01Reth + protocolReth) / 2);
    }

    /**
    * Tests the deviation check works and calls _callFallbackOracle when the TWAP and 
    * Chainlink prices are off by more than 1%.
    */
    function test_failed_offprice_deviation() public {
        //Pre-condition + Action
        _mock_false_chainlink_feed(rEthEthChainlink);

        //Post-conditions
        uint uni01Reth = OZ.getUniPrice(1, Dir.UP);
        uint protocolReth = IRocketTokenRETH(rEthAddr).getExchangeRate();
        uint backupReth = OZ.rETH_ETH();

        assertTrue(backupReth == (uni01Reth + protocolReth) / 2);


    }






}




