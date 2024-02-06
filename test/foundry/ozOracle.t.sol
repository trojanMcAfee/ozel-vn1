// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "../../contracts/libraries/oracle/OracleLibrary.sol";
import {IUsingTellor} from "../../contracts/interfaces/IUsingTellor.sol";
import {IRocketTokenRETH} from "../../contracts/interfaces/IRocketPool.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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


    function test_medium_callFallbackOracle_rETHETH() public {
        //Pre-condition
        _mock_false_chainlink_feed(rEthEthChainlink);

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

    //To test if Tellor and RedStone prices are properly fetched, I need to create mocks,
    //and play with the functions so that the medium value returned is Tellor or RedStone.






}




