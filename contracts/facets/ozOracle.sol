// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage, LastRewards} from "../AppStorage.sol";
import {IPool} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IRocketTokenRETH} from "../interfaces/IRocketPool.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import {IERC20Permit} from "../interfaces/IERC20Permit.sol";
import {IUsingTellor} from "../interfaces/IUsingTellor.sol";
import "../Errors.sol";

import {OracleLibrary} from "../libraries/oracle/OracleLibrary.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import "forge-std/console.sol";



contract ozOracle {

    using FixedPointMathLib for uint;

    AppStorage private s;

    uint constant public TIMEOUT_LINK = 4 hours; //14400 secs - put this inside AppStorage
    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    

    event OzRewards(
        uint blockNumber, 
        uint ozelFeesInRETH, 
        int totalRewards, 
        int currentRewards
    );


    function rETH_ETH() public view returns(uint) {
        (bool success, uint price) = _useLinkInterface(s.rEthEthChainlink, true);
        return success ? price : _callFallbackOracle(s.rETH); 
    }


    function ETH_USD() public view returns(uint) {
        (bool success, uint price) = _useLinkInterface(s.ethUsdChainlink, true);
        return success ? price : _callFallbackOracle(s.WETH);  
    }

    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether;
    }


    //----------
    function _useLinkInterface(address priceFeed_, bool isLink_) private view returns(bool, uint) {
        uint timeout = TIMEOUT_LINK;
        uint BASE = 1e10;

        if (!isLink_) timeout = TIMEOUT_EXTENDED;
        if (priceFeed_ == s.rEthEthChainlink) BASE = 1;

        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();


        if (
            (roundId != 0 || _exemptRed(priceFeed_)) && 
            answer > 0 && 
            updatedAt != 0 && 
            updatedAt <= block.timestamp &&
            block.timestamp - updatedAt <= timeout
        ) {
            return (true, uint(answer) * BASE); 
        } else {
            return (false, 0); 
        }
    }


    function _getUniPrice(address token0_, address token1_, uint24 fee_) private view returns(uint) {
        address pool = IUniswapV3Factory(s.uniFactory).getPool(token0_, token1_, fee_);
        uint32 secondsAgo = uint32(10);
        uint BASE = 1e12;

        if (token1_ == s.WETH) BASE = 1;

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 tick = int24(tickCumulativesDelta / int32(secondsAgo));
        
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secondsAgo) != 0)) tick--;
        
        uint amountOut = OracleLibrary.getQuoteAtTick(
            tick, 1 ether, token0_, token1_
        );
    
        return amountOut * BASE;
    }


    function _getTellorPrice() private view returns(bool, uint) { 
        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth","usd")));

        (bool success, bytes memory value, uint timestamp) = 
            IUsingTellor(s.tellorOracle).getDataBefore(queryId, block.timestamp - DISPUTE_BUFFER);

        if (!success || block.timestamp - timestamp > TIMEOUT_EXTENDED) return (false, 0);

        return (true, abi.decode(value, (uint)));
    }


    function _getRedPrice() private view returns(bool, uint) {
        (bool success, uint weETH_ETH) = _useLinkInterface(s.weETHETHredStone, false);
        (bool success2, uint weETH_USD) = _useLinkInterface(s.weETHUSDredStone, false);

        if (success && success2) {
            uint price = (1 ether ** 2 / weETH_ETH).mulDivDown(weETH_USD, 1 ether);
            return (true, price);
        } else {
            return (false, 0);
        }
    }


    function _callFallbackOracle(address baseToken_) private view returns(uint) {
        if (baseToken_ == s.WETH) {
            uint uniPrice = _getUniPrice(s.WETH, s.USDC, s.uniFee);
            (bool success, uint tellorPrice) = _getTellorPrice();
            (bool success2, uint redPrice) = _getRedPrice();

            if (success && success2) {
                return Helpers.getMedium(uniPrice, tellorPrice, redPrice);
            } else {
                return uniPrice;
            }
        } else if (baseToken_ == s.rETH) {
            uint uniPrice05 = _getUniPrice(s.rETH, s.WETH, s.uniFee);
            uint uniPrice01 = _getUniPrice(s.rETH, s.WETH, s.uniFee01);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return Helpers.getMedium(uniPrice05, uniPrice01, protocolPrice);
        }
        revert OZError23(baseToken_);
    }

    //RedStone's weETH/ETH price feed's contract doesn't implement verification logic
    //for roundId so the value is always 0.
    function _exemptRed(address feed_) private view returns(bool) {
        return feed_ == s.weETHETHredStone;
    }


    //------

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

        // console.log('-----');
        // console.log('rETH_USD(): ', rETH_USD());
        // console.log('amountReth: ', amountReth);
        // console.log('ETH_USD(): ', ETH_USD());
        console.log('rETH_ETH(): ', rETH_ETH());
        // console.log('is: ', (rETH_USD() * amountReth) / 1 ether);
        // console.log('-----');

        // uint a = rETH_USD();
        // uint b = amountReth;
        // uint c = 1 ether;

        // uint x = (a * b) 

        return (rETH_USD() * amountReth) / 1 ether;
    }

    //check this
    function getLastRewards() external view returns(LastRewards memory) {
        return s.rewards;
    }


    function chargeOZLfee() external returns(bool) { 
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this)); 

        uint totalAssets;
        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i].ozToken).totalAssets();
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
        uint adminFee = uint(s.adminFee).mulDivDown(grossFees_, 10_000); 
        IERC20Permit(s.rETH).transfer(s.adminFeeRecipient, adminFee);

        return grossFees_ - adminFee;
    }
}
