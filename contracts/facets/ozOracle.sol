// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage, LastRewards} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {IERC20Permit} from "../interfaces/IERC20Permit.sol";
import "../Errors.sol";

import {OracleLibrary} from "../libraries/oracle/OracleLibrary.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";


import "forge-std/console.sol";


contract ozOracle {

    using FixedPointMathLib for uint;

    AppStorage private s;

    event OzRewards(
        uint blockNumber, 
        uint ozelFeesInRETH, 
        int totalRewards, 
        int currentRewards
    );


    //validate with lastTimeUpdated
    function rETH_ETH() public view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        return uint(price);
    }

    // function ETH_USD() public view returns(uint) {
    //     (,int price,,,) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();
    //     return uint(price) * 1e10;
    // }

    function _getLinkPrice(address priceFeed_) private view returns(
        bool, uint80, int, uint
    ) {
        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(s.ethUsdChainlink).latestRoundData();

        return (true, roundId, answer, updatedAt);
    }

    function ETH_USD() public view returns(uint price) {
        (
            bool success,
            uint80 roundId,
            int answer,
            uint updatedAt
        ) = _getLinkPrice(s.ethUsdChainlink);

        if (
            success &&
            roundId != 0 && 
            answer > 0 && 
            updatedAt != 0 && 
            updatedAt <= block.timestamp
        ) {
            price = uint(answer) * 1e10;
        } else {
            price = _callFallbackOracle();
        }
        console.log('price: ', price);
        
    }


    function _callFallbackOracle() private view returns(uint) {
        address pool = IUniswapV3Factory(s.uniFactory).getPool(s.WETH, s.USDC, s.uniFee);

        (int24 tick,) = OracleLibrary.consult(pool, uint32(10));

        uint256 amountOut = OracleLibrary.getQuoteAtTick(
            tick, 1 ether, s.WETH, s.USDC
        );
    
        int priceUni = int(amountOut * 1e12);
        return uint(priceUni);
    }


    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether ^ 2;
    }


    function setValuePerOzToken(address ozToken_, uint amount_, bool addOrSub_) external { //put an onlyOzToken mod
        if (addOrSub_) {
            s.valuePerOzToken[ozToken_] += amount_;
        } else {
            s.valuePerOzToken[ozToken_] -= amount_;
        }
    }


    function getUnderlyingValue(address ozToken_) external view returns(uint) {
        uint amountReth = ozToken_ == address(this) ?
            IERC20Permit(s.rETH).balanceOf(address(this)) :
            s.valuePerOzToken[ozToken_]; 
   
        uint rate = IRocketTokenRETH(s.rETH).getExchangeRate(); 

        return ( ((rate * amountReth) / 1 ether) * ETH_USD() ) / 1 ether;        
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

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        (uint assetsInETH, uint valueInETH) = _calculateValuesInETH(totalAssets, amountReth);

        // console.log('assetsInETH: ', assetsInETH);
        // console.log('valueInETH: ', valueInETH);
        // console.log('----');
        // console.log('amountReth total: ', IERC20Permit(s.rETH).balanceOf(address(this)));
        
        // console.log('ETH_USD: ', ETH_USD());
        // console.log('rETH_ETH: ', rETH_ETH());

        // console.log('rETH_USD: ', rETH_USD());
        // console.log('totalAssets - stables: ', totalAssets * 1e12);
        // console.log('----');

        int totalRewards = int(valueInETH) - int(assetsInETH); 
        /**
         * this line needs to be thoroughly tested out ^.
         * edge case --> when the protocol is ready to accrue rewards, but then a new stable
         * deposit comes in that increases assetsInETH. the invariant from above will brake and 
         * no rewards-accrual will be possible.
         * .
         * Consider putting a check that when valueInETH > assetsInETH, something/someone calls chargeOZLfee()
         * Decrease the gas consumption of this function as much as possible.
         * Consider adding a call to this function in an user-calling function. 
         */

        // console.logInt(totalRewards);
        // console.log('totalRewards ^^');

        if (totalRewards <= 0) return false;

        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards); //this too (further testing)

        // console.logInt(currentRewards);
        // console.log('currentRewards ^^');

        if (currentRewards <= 0) return false;

        uint ozelFeesInRETH = _getFeeAndForward(totalRewards, currentRewards);      

        emit OzRewards(block.number, ozelFeesInRETH, totalRewards, currentRewards);

        return true;
    }


    function _getFeeAndForward(int totalRewards_, int currentRewards_) private returns(uint) {
        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards_), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards_);

        uint grossOzelFeesInRETH = (ozelFeesInETH * 1 ether) / rETH_ETH();

        uint netOzelFees = _getAdminFee(grossOzelFeesInRETH);

        IERC20Permit(s.rETH).transfer(s.ozlProxy, netOzelFees);
        
        return netOzelFees;
    }


    /**
     * @dev Calculates the values in ETH of the variables
     * @param assets_ How much in stablecoins there are in ozToken contrats
     * @param amountReth_ How much rETH in total the protocol manages
     * @return (uint, uint) - assets_ valued in ETH / all protocol rETH valued in ETH
     */
    function _calculateValuesInETH(uint assets_, uint amountReth_) private view returns(uint, uint) {
        uint assetsInETH = ((assets_ * 1e12) * 1 ether) / ETH_USD();
        uint valueInETH = (amountReth_ * rETH_ETH()) / 1 ether;

        return (assetsInETH, valueInETH);
    }

    function _getAdminFee(uint grossFees_) private returns(uint) {
        uint adminFee = uint(50).mulDivDown(grossFees_, 10_000); //put here adminFeeBps - 50
        IERC20Permit(s.rETH).transfer(s.adminFeeRecipient, adminFee);

        return grossFees_ - adminFee;
    }

}


/**
     * add a fallback oracle like uni's TWAP
     **** handle the possibility with Chainlink of Sequencer being down (https://docs.chain.link/data-feeds/l2-sequencer-feeds)
     */