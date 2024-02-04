// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";

interface MyInter {
    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


contract ozOracleTest is TestMethods {

    function test_ETH_USD() public {

        uint ethPrice = OZ.ETH_USD();
        console.log("ethPrice in test: ", ethPrice);

    }

    function _mock_false_chainlink_feed(address feed_) internal {
        vm.mockCall(
            feed_,
            abi.encodeWithSignature('latestRoundData()'),
            abi.encode(uint80(0), int(0), uint(0), uint(0), uint80(0))
        );
    }

    

    function test_x() public {

        // vm.rollFork(redStoneBlock);
        // vm.rollFork(mainFork, redStoneBlock);
        vm.selectFork(redStoneFork);

        _mock_false_chainlink_feed(ethUsdChainlink);
    
        uint ethPrice = OZ.ETH_USD();
        console.log("ethPrice in test: ", ethPrice);

    }




}




