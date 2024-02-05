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


    function _getUniPrice() internal view returns(uint) {
        address pool = IUniswapV3Factory(uniFactory).getPool(wethAddr, usdcAddr, uniPoolFee);

        (int24 tick,) = OracleLibrary.consult(pool, uint32(10));

        uint256 amountOut = OracleLibrary.getQuoteAtTick(
            tick, 1 ether, wethAddr, usdcAddr
        );
    
        return amountOut * 1e12;
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


    function test_h() public { //test_medium_callFallbackOracle_rETHETH
        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("reth", "usd")));

        (bool success, bytes memory value, uint timestamp) = 
            IUsingTellor(tellorOracle).getDataBefore(queryId, block.timestamp - 15 minutes);

        uint x = abi.decode(value, (uint));
        console.log('tellor - reth/usd: ', x);

        //-------
        address pool = IUniswapV3Factory(uniFactory).getPool(rEthAddr, wethAddr, uniPoolFee);

        (int24 tick,) = OracleLibrary.consult(pool, uint32(10));

        uint256 amountOut = OracleLibrary.getQuoteAtTick(
            tick, 1 ether, rEthAddr, wethAddr
        );

        console.log('uni reth/eth: ', amountOut);
        //--------

        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        console.log('link eth/usd', uint(price));
        //---------

        uint rate = IRocketTokenRETH(rEthAddr).getExchangeRate();
        console.log('reth/eth: ', rate);
        
    }

    
    function test_medium_callFallbackOracle_ETHUSD() public {
        //Pre-condtions
        vm.selectFork(redStoneFork);

        _mock_false_chainlink_feed(ethUsdChainlink);
    
        //Action
        uint ethPrice = OZ.ETH_USD();
        console.log('ethPrice: ', ethPrice);

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




