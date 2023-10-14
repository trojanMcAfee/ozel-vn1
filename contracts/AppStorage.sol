// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


/**
 * @notice Main storage structs
 */
struct AppStorage { 

    address[] ozTokenRegistry;
    address ozDiamond;
    address WETH;

    address swapRouterUni;
    address ethUsdChainlink; //consider removing this since minOut is calculated in the FE

    uint defaultSlippage;
    address vaultBalancer;
    address queriesBalancer;

    address rETH;
    address rEthWethPoolBalancer;
    address rEthEthChainlink;

    mapping(address underlying => address token) ozTokens;
    address[] ozTokensArr;
    uint rewardMultiplier;
  
}

struct TradeAmounts {
    uint amountIn;
    uint minWethOut;
    uint minRethOut;
    uint minBptOut;
}

// struct ozToken {
//     address self;
//     address underlying;
//     string name;
//     string symbol;
//     uint totalShares;
//     mapping(address => uint) shares;
//     mapping(address => mapping(address => uint256)) allowances;
//     //add here later Permit vars
// }













