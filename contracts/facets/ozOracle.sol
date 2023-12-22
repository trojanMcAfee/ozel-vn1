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

    function rETH_USD() external view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether ^ 2;
    }

    function getUnderlyingValue() public view returns(uint) {
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));    
        uint rate = IRocketTokenRETH(s.rETH).getExchangeRate();    

        uint grossRethValue =  ( ((rate * amountReth) / 1 ether) * ETH_USD() ) / 1 ether; 

        return grossRethValue;

        // uint totalAssets;
        // for (uint i=0; i < s.ozTokenRegistry.length; i++) {
        //     totalAssets += ozIToken(s.ozTokenRegistry[i]).totalAssets();
        // }

        // if ((totalAssets * 1e12) > grossRethValue) {
        //     return grossRethValue;
        // } else {
        //     (uint netUnderlyingValue,) = _applyFee(grossRethValue, totalAssets);
        //     return netUnderlyingValue;
        // }
    }

    // struct LastRewards {
    //     uint amountRewards;
    //     uint startBlock;
    //     uint endBlock;
    // }


    function chargeOZLfee() external returns(bool) { // function _applyFee(uint grossRethValue_, uint totalAssets_)
        // grossRethValue --- 100% 10_000
        //    x ------- 15% 1_500
        console.log('here');

        uint grossRethValue = getUnderlyingValue();

        uint totalAssets;
        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i]).totalAssets();
        }

        //------

        if (block.number <= s.rewards.blockNumber) revert OZError14(block.number);

        uint totalRewards = grossRethValue - totalAssets;
        int currentRewards = int(totalRewards) - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;

        uint ozelFees = uint(s.protocolFee).mulDivDown(uint(currentRewards), 10_000);
        s.rewards.prevTotalRewards = totalRewards;

        _forwardFees(ozelFees); //forwards fees to OZL - withdraws it from rETH bal

        // emit OZLrewards(block.number, totalRewards, ozelFees, netUnderlyingValue);

        return true;

        //------

        // if (currentRewards > 0) {
        //     uint ozelFees = uint(s.protocolFee).mulDivDown(currentRewards, 10_000);
        //     s.rewards.prevTotalRewards = totalRewards;

        //     _forwardFees(ozelFees); //forwards fees to OZL - withdraws it from rETH bal
        //     //do this next ^

        //     emit OZLrewards(block.number, totalRewards, ozelFees, netUnderlyingValue);

        //     return true
        // } else {
        //     //No rewards
        //     return false;
        // }

        //-------
        // s.rewards.endBlock = s.rewards.startBlock; 

        // uint currentCycleRewards = totalRewards;
        // s.rewards.accumulated += totalRewards;

        // s.rewards.startBlock = block.number;
        // s.rewards.prevTotalRewards = totalRewards;
        // //-------

        // uint ozelFees = uint(s.protocolFee).mulDivDown(totalRewards, 10_000);
        // uint netUnderlyingValue = grossRethValue_ - ozelFees;

        // emit OZLrewards(block.number, totalRewards, ozelFees, netUnderlyingValue);

        // return (netUnderlyingValue, ozelFees);
    }


    function _forwardFees(uint ozelFeesInUSD_) private {
        // getUnderlyingValue --- 100%
        //    ozelFeesInUSD_ ------- x = 

        uint feesPercentage = ozelFeesInUSD_.mulDivDown(10_000, getUnderlyingValue());

        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this));

        // amountReth -- 100%
        //     x ------ feesPercentage

        uint amountRethForward = feesPercentage.mulDivDown(amountReth, 10_000);
        IERC20Permit(s.rETH).transfer(s.ozlProxy, amountRethForward);

    }



}


/**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */