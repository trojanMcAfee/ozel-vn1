// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {IsfrxETH} from "../interfaces/IFrax.sol";

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
        return uint(price) * 1e10;
    }


    function getUnderlyingValue() external view returns(uint) {
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));   
        uint amountSfrxEth = IERC20Permit(s.sfrxETH).balanceOf(address(this));

        uint rEthRate = IRocketTokenRETH(s.rETH).getExchangeRate();   
        uint frxRate = IsfrxETH(s.sfrxETH).pricePerShare();

        return _convertToUSD(rEthRate, amountReth) + _convertToUSD(frxRate, amountSfrxEth);
    }

    function _convertToUSD(uint rate_, uint amount_) private view returns(uint) {
        return ( ((rate_ * amount_) / 1 ether) * ETH_USD() ) / 1 ether;
    }


}