// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "../../contracts/libraries/oracle/OracleLibrary.sol";

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

    
    function test_medium_callFallbackOracle() public {
        //Pre-condtions
        vm.selectFork(redStoneFork);

        _mock_false_chainlink_feed(ethUsdChainlink);
    
        //Action
        uint ethPrice = OZ.ETH_USD();

        //Post-condition
        assertTrue(ethPrice == _getUniPrice());
    }


    function test_lastOption_uniPrice_callFallbackOracle() public {
        //Pre-condtions
        vm.selectFork(redStoneFork);

        _mock_false_chainlink_feed(ethUsdChainlink);
        _mock_false_chainlink_feed(weETHETHredStone);

        //Action
        uint ethPrice = OZ.ETH_USD();

        //Post-condition
        assertTrue(ethPrice == _getUniPrice());

    }






}




