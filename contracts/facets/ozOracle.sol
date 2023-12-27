// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage, LastRewards} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import "../Errors.sol";

import {IERC20Permit} from "../interfaces/IERC20Permit.sol";

import "forge-std/console.sol";


contract ozOracle {

    using FixedPointMathLib for uint;

    AppStorage private s;

    event OZLrewards(
        uint blockNumber, 
        uint totalRewards, 
        uint ozelFees, 
        uint netUnderlyingValue
    );

    //validate with lastTimeUpdated
    function rETH_ETH() public view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        return uint(price);
    }

    function ETH_USD() public view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
        return uint(price) * 1e10;
    }

    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether ^ 2;
    }


    function getUnderlyingValue() public view returns(uint) {
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));    
        console.log('amountReth in ozOracle: ', amountReth);

        uint rate = IRocketTokenRETH(s.rETH).getExchangeRate(); 
        // console.log('ETH_USD: ', ETH_USD());   

        uint grossRethValue =  ( ((rate * amountReth) / 1 ether) * ETH_USD() ) / 1 ether; 

        return grossRethValue;
       
    }


    function getLastRewards() external view returns(LastRewards memory) {
        return s.rewards;
    }


    function chargeOZLfee() external returns(bool) { 
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this)); 

        uint totalAssets;
        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i]).totalAssets();
        }

        //------

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        (uint assetsInETH, uint valueInETH) = _calculateValuesInETH(totalAssets, amountReth);

        int totalRewards = int(valueInETH) - int(assetsInETH);

        if (totalRewards <= 0) return false;

        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;

        _getFeeAndForward(totalRewards, currentRewards);      

        // emit OZLrewards(block.number, totalRewards, ozelFees, netUnderlyingValue);

        return true;
    }

    function _getFeeAndForward(int totalRewards_, int currentRewards_) private {
        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards_), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards_);

        uint ozelFeesInRETH = (ozelFeesInETH * 1 ether) / rETH_ETH();
        IERC20Permit(s.rETH).transfer(s.ozlProxy, ozelFeesInRETH);
    }

    function _calculateValuesInETH(uint assets_, uint amountReth_) private view returns(uint, uint) {
        uint assetsInETH = ((assets_ * 1e12) * 1 ether) / ETH_USD();
        uint valueInETH = (amountReth_ * rETH_ETH()) / 1 ether;

        return (assetsInETH, valueInETH);
    }



}


/**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */