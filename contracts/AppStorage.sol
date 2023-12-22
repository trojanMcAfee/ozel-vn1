// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


/**
 * @notice Main storage structs
 */
struct AppStorage { 

    address rEthWethPoolBalancer; //don't change this from 1st pos
    address[] ozTokenRegistry;
    address ozDiamond;
    address WETH; 
    address USDC;
    address USDT;

    address swapRouterUni;
    address ethUsdChainlink; //consider removing this since minOut is calculated in the FE

    uint16 defaultSlippage;
    address vaultBalancer;
    address queriesBalancer;

    address rETH;
    address rEthEthChainlink;

    mapping(address underlying => address token) ozTokens;
    address[] ozTokensArr;
    uint rewardMultiplier; //remove if not used

    address ozBeacon;

    address rocketPoolStorage;
    bytes32 rocketDepositPoolID;
    address rocketVault;
    bytes32 rocketDAOProtocolSettingsDepositID;

    uint24 uniFee;

    mapping(address ozToken => bool exist) ozTokenRegistryMap;

    uint24 protocolFee;

    address ozlProxy;

    LastRewards rewards;
  
}


struct AmountsIn {
    uint amountIn;
    uint minWethOut;
    uint minRethOut;
}




struct AmountsOut {
    uint128 ozAmountIn;
    uint128 minWethOut;
    uint bptAmountIn;
    uint minUsdcOut;
}



enum Asset {
    USD,
    UNDERLYING
}


/**
 * DiamondInit structs
 */
struct Tokens {
    address weth;
    address reth;
    address usdc;
    address usdt;
}

struct Dexes {
    address swapRouterUni;
    address vaultBalancer;
    address queriesBalancer;
    address rEthWethPoolBalancer;
}

struct Oracles {
    address ethUsdChainlink;
    address rEthEthChainlink;
}

struct Infra { 
    address ozDiamond;
    address beacon;
    address rocketPoolStorage;
    uint16 defaultSlippage; 
    uint24 uniFee;
    uint24 protocolFee;
    address ozlProxy;
}

//-----

struct LastRewards {
    uint lastBlock;
    uint prevTotalRewards;
}


// 1st round - 
// rETH        - 110
// totalAssets - 100
// ---
// currentRewards = totalRewards(110 - 100 = 10) - prevTotalRewards(0) = 10

// 2nd round -
// rETH        - 112
// totalAssets - 100
// ----
// currentRewards = totalRewards(112 - 100 = 12) - prevTotalRewards(10) = 2

// 3rd round - 
// rETH        - 117
// totalAssets - 100
// ----
// currentRewards = totalRewards(117 - 100 = 17) - prevTotalRewards(12) = 5

// 4th roud -
// rETH        - 116
// totalAssets - 100
// ----
// currentRewards = totalRewards(116 - 100 = 16) - prevTotalRewards(17) = -1


