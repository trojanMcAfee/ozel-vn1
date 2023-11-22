// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";

import "forge-std/console.sol";


contract ozOracle {

    AppStorage private s;

    //validate with lastTimeUpdated
    function rETH_ETH() external view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        return uint(price);
    }

    function ETH_USD() public view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
        return uint(price);
    }

    // function getUnderlyingValue() external view returns(uint) {
    //     uint amountBpt = IERC20Permit(s.rEthWethPoolBalancer).balanceOf(address(this));        
    //     uint bptPrice = IPool(s.rEthWethPoolBalancer).getRate(); 
    //     (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();

    //     return ( ((bptPrice * amountBpt) / 1 ether) * (uint(price) * 1e10) ) / 1 ether; 
    // } 

    function getUnderlyingValue() external view returns(uint) {
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));    
        uint rate = IRocketTokenRETH(s.rETH).getExchangeRate();    
        (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();

        return ( ((rate * amountReth) / 1 ether) * (uint(price) * 1e10) ) / 1 ether; 
    }


}