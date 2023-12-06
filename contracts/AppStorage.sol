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
    address USDC;
    address USDT;

    address swapRouterUni;
    address ethUsdChainlink; //consider removing this since minOut is calculated in the FE

    uint defaultSlippage;
    address vaultBalancer;
    address queriesBalancer;

    address rETH;
    address rEthWethPoolBalancer; //if balancer is no longer used in L1, remove it
    address rEthEthChainlink;

    mapping(address underlying => address token) ozTokens;
    address[] ozTokensArr;
    uint rewardMultiplier; //remove if not used

    address ozBeacon;

    address rocketPoolStorage;
    bytes32 rocketDepositPoolID;
    address rocketVault;
    bytes32 rocketDAOProtocolSettingsDepositID;

    address frxETHminter;
    address sfrxETH;
  
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
    address sfrxEth;
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

struct DiamondInfra { //modify this to Infra
    address ozDiamond;
    address beacon;
    address rocketPoolStorage;
    uint defaultSlippage; //try chaning this to an uin8
    address frxETHminter;
}














