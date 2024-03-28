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


contract SwapRouterMock {
    event DeadVar(ExactInputSingleParams params);

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
        emit DeadVar(params);

        address ozDiamond = 0x92a6649Fdcc044DA968d94202465578a9371C7b1;
        uint amountOut = 19662547189176713;

        if (IERC20(params.tokenIn).balanceOf(address(1)) == 27444635666) {
            amountOut = 19662545835237478;
        }

        if (params.amountIn == 19646820040369690) {
            amountOut = 32940641;
            IERC20(params.tokenOut).transfer(params.recipient, amountOut);
        }
        
        IERC20(params.tokenIn).transferFrom(msg.sender, address(1), params.amountIn);
        
        if (IERC20(params.tokenOut).balanceOf(address(this)) / 1e18 != 0) {
            IERC20(params.tokenOut).transfer(ozDiamond, amountOut);
        }

        if (params.amountIn == 33000000) return amountOut;
        
        return amountOut;
    }
}


contract VaultMock {

    using FixedPointMathLib for *;

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


    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint) {
        // address ozDiamond = 0x92a6649Fdcc044DA968d94202465578a9371C7b1; 
        ozIDiamond OZ = ozIDiamond(0x92a6649Fdcc044DA968d94202465578a9371C7b1);
        uint amountOut;

        IERC20(address(singleSwap.assetIn)).transferFrom(address(OZ), address(1), singleSwap.amount);
    

        if (singleSwap.amount == 19662547189176713) amountOut = 18081415515835888;
        if (singleSwap.amount == 19662545835237478) amountOut = 18081413499483890;
        if (singleSwap.amount == 18081414507659889) {
            console.log('OZ.rETH_ETH() in mock: ', OZ.rETH_ETH());

            amountOut = (18081414507659889).mulDivDown(OZ.rETH_ETH(), 1e18);
            console.log('amountOut in mock - 20431028919899640: ', amountOut);
            
            // amountOut = 19646820040369690;
        }
        // if (singleSwap.amount == 18081414507659889) amountOut = 19646820040369690;

        IERC20(address(singleSwap.assetOut)).transfer(address(OZ), amountOut);
        
        emit DeadVars(funds, limit, deadline);

        return amountOut;
    }
}