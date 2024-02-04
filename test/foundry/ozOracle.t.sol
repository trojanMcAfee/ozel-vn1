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


    function test_



    function test_x() public {
        address priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; //chainlink
        address priceFeed2 = 0xdDb6F90fFb4d3257dd666b69178e5B3c5Bf41136; //redStone

        // console.log('block roll pre: ', block.number);
        vm.rollFork(redStoneBlock);
        // console.log('block roll post: ', block.number);

        MyInter feed = MyInter(priceFeed2);
        (,int answer,,,) = feed.latestRoundData();
        
        console.log('answer: ', uint(answer));

    }




}