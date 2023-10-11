// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage} from "../AppStorage.sol";


contract ozOracles {

    AppStorage private s;


    function rETH_ETH() external view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        return uint(price);
    }


}