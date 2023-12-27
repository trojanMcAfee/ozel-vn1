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
     
        // uint grossRethValue = getUnderlyingValue();
        uint grossRethValue = IERC20Permit(s.rETH).balanceOf(address(this)); 

        uint totalAssets;
        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i]).totalAssets();
        }

        //------

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        uint assetsInETH = ((totalAssets * 1e12) * 1 ether) / ETH_USD();
        uint valueInETH = (grossRethValue * rETH_ETH()) / 1 ether;

        console.log('valueInETH: ', valueInETH);
        console.log('assetsInETH: ', assetsInETH);

        // int totalRewards = int(grossRethValue) - int( ( (totalAssets * 1e12) * ETH_USD() ) * rETH_ETH() );
        int totalRewards = int(valueInETH) - int(assetsInETH);


        console.log('.');
        console.log('totalRewards in oracle: ', uint(totalRewards));
        console.log('grossRethValue (under) in oracle: ', grossRethValue);
        console.log('totalAssets in oracle: ', totalAssets * 1e12);
        console.log('rETH_USD: ', rETH_USD());
        console.log('prevTotalRewards: ', s.rewards.prevTotalRewards);

        console.log('-- increase --');
        console.log('rETH_ETH: ', rETH_ETH());
        console.log('ETH_USD: ', ETH_USD());
        console.log('-- increase --');
        console.log('totalRewards in oracle: ', uint(totalRewards));

        if (totalRewards <= 0) return false;

        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;

        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards);

        _forwardFees(ozelFeesInETH);

        console.log('.');
        console.log('rEth total: ', IERC20Permit(s.rETH).balanceOf(address(this)));
        // console.log('grossRethValue in USD: ', grossRethValue);
        console.log('ozelFees in ETH: ', ozelFeesInETH);

        // emit OZLrewards(block.number, totalRewards, ozelFees, netUnderlyingValue);

        return true;
        
    }


    function _forwardFees(uint ozelFeesInETH_) private {
        // 1 rETH --- 1.08 ETH (rETH_ETH)
        //     x ----- ozelFeesInETH_

        // uint feesPercentage = ozelFeesInETH_.mulDivDown(10_000, getUnderlyingValue());

        uint ozelFeesInRETH = (ozelFeesInETH_ * 1 ether) / rETH_ETH();
        console.log('ozelFeesInRETH: ', ozelFeesInRETH);

        // uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));

        // amountReth -- 100%
        //     x ------ feesPercentage

        // uint amountRethToForward = feesPercentage.mulDivDown(amountReth, 10_000);
        IERC20Permit(s.rETH).transfer(s.ozlProxy, ozelFeesInRETH);

    }



}


/**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */