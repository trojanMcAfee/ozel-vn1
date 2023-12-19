// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


contract ozOracle {

    using FixedPointMathLib for uint;

    AppStorage private s;

    //validate with lastTimeUpdated
    function rETH_ETH() public view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        return uint(price);
    }

    function ETH_USD() public view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
        return uint(price) * 1e10;
    }

    function rETH_USD() external view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether ^ 2;
    }

    function getUnderlyingValue() external view returns(uint) {
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));    
        uint rate = IRocketTokenRETH(s.rETH).getExchangeRate();    

        uint subTotal =  ( ((rate * amountReth) / 1 ether) * ETH_USD() ) / 1 ether; 
        console.log('total after fees: ', applyFee(subTotal));
        return subTotal;
    }

    function applyFee(uint subTotal_) public pure returns(uint) {
        // subTotal --- 100% 10_000
        //    x ------- 15% 1_500
        uint fee = 1_500;

        return subTotal_ - fee.mulDivDown(subTotal_, 10_000);
    }
}


/**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */