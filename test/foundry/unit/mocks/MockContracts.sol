// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {MockStorage} from "../MockStorage.sol";
import {IAsset} from "../../../../contracts/interfaces/IBalancer.sol";
import {ozIDiamond} from "../../../../contracts/interfaces/ozIDiamond.sol";
import {IERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import {FixedPointMathLib} from "../../../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


/**
 * Has the rETH-ETH price before staking rewards accrual +
 * how to get historical rETH-ETH price
 */
contract RethLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(18446744073709551854),
            int(rETHPreAccrual),
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }

    function getRoundData(uint80 roundId_) external pure returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        int price;

        if (roundId_ == 18446744073709551853) price = 1085995250282916400;
        if (roundId_ == 0) price = 1086486906594931900;

        return (
            uint80(1),
            price,
            1,
            1,
            uint80(1)
        );
    }
}


//Has the rETH-ETH price after staking rewards accrual
contract RethLinkFeedAccrued is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(rETHPostAccrual),
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}


contract RethPreAccrualTWAP {

    function observe(uint32[] calldata secondsAgos) external view returns(
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s
    ) {
        secondsPerLiquidityCumulativeX128s = new uint160[](1);
        secondsPerLiquidityCumulativeX128s[0] = 2;
        tickCumulatives = new int56[](2);

        if (secondsAgos[0] == 1800) {
            tickCumulatives[0] = 27639974418;
            tickCumulatives[1] = 27641473818;
        } else if (secondsAgos[0] == 86400) {
            tickCumulatives[0] = 27569162970;
            tickCumulatives[1] = 27641473818;
        }

        return (tickCumulatives, secondsPerLiquidityCumulativeX128s);
    }
}


contract RethAccruedTWAP {

    function observe(uint32[] calldata secondsAgos) external view returns(
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s
    ) { 
        secondsPerLiquidityCumulativeX128s = new uint160[](1);
        secondsPerLiquidityCumulativeX128s[0] = 2;

        tickCumulatives = new int56[](2);
        tickCumulatives[0] = 48369955231;
        tickCumulatives[1] = 48372579181;

        return (tickCumulatives, secondsPerLiquidityCumulativeX128s);
    }
}



//Has current ETH-USD price
contract EthLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(currentPriceETH) / 1e10,
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}


/**
 * Simulates swaps with accurate (and simulated) price feeds for every pair,
 * disregarding liquidity unbalances, among other liquidity factors, in the 
 * output of amount of tokens out.
 */
contract SwapRouterMock is MockStorage {
    using FixedPointMathLib for *;

    ozIDiamond immutable OZ;

    constructor(address ozDiamond_) {
        OZ = ozIDiamond(ozDiamond_);
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint) {
        uint amountOut;

        if (params.tokenIn == USDC) amountOut = (params.amountIn * 1e12).mulDivDown(1e18, OZ.ETH_USD());
    
        if (params.tokenIn == WETH) {
            amountOut = (params.amountIn.mulDivDown(OZ.ETH_USD(), 1 ether)) / 1e12;   
            IERC20(params.tokenOut).transfer(params.recipient, amountOut);
            return amountOut;
        }
        
        IERC20(params.tokenIn).transferFrom(msg.sender, address(1), params.amountIn);
        
        if (IERC20(params.tokenOut).balanceOf(address(this)) / 1e18 != 0) {
            IERC20(params.tokenOut).transfer(address(OZ), amountOut);
        }

        if (params.amountIn == 33000000) return amountOut;
        
        return amountOut;
    }
}


//Same as above.
contract VaultMock {

    using FixedPointMathLib for *;


    ozIDiamond immutable OZ;

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    event DeadVars(FundManagement funds, uint limit, uint deadline);

    constructor(address ozDiamond_) {
        OZ = ozIDiamond(ozDiamond_);
    }


    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint) {
        // ozIDiamond OZ = ozIDiamond(0x92a6649Fdcc044DA968d94202465578a9371C7b1);
        uint amountOut;

        IERC20(address(singleSwap.assetIn)).transferFrom(address(OZ), address(1), singleSwap.amount);

        if (singleSwap.amount == 19673291323457014) 
        { 
            uint wethIn = 19673291323457014;
            amountOut =  wethIn.mulDivDown(1 ether, OZ.rETH_ETH());
        } 

        if (singleSwap.amount == 18107251181805252) { 
            uint rETHin = 18107251181805252;
            amountOut = rETHin.mulDivDown(OZ.rETH_ETH(), 1e18);
        }

        IERC20(address(singleSwap.assetOut)).transfer(address(OZ), amountOut);
        
        emit DeadVars(funds, limit, deadline);

        return amountOut;
    }
}