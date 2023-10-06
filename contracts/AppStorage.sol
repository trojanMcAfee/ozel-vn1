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
  
}













