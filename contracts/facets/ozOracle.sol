// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
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

        uint totalAssets;
        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i]).totalAssets();
        }

        // uint total = (totalAssets * 1e12) > subTotal ? subTotal : _applyFee(subTotal, totalAssets);

        if ((totalAssets * 1e12) > subTotal) {
            return subTotal;
        } else {
            (uint netUnderlyingValue,) = _applyFee(subTotal, totalAssets);
            return netUnderlyingValue;
        }
    }


    function _applyFee(uint subTotal_, uint totalAssets_) private view returns(uint, uint) {
        // subTotal --- 100% 10_000
        //    x ------- 15% 1_500
        console.log('here');

        uint totalRewards = subTotal_ - totalAssets_;

        uint ozelRewards = uint(s.protocolFee).mulDivDown(totalRewards, 10_000);
        uint netUnderlyingValue = subTotal_ - ozelRewards;

        return (netUnderlyingValue, ozelRewards);
    }


}


/**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */