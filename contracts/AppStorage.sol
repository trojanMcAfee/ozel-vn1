// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";


/**
 * @notice Main storage structs
 */
struct AppStorage { 


    address rEthWethPoolBalancer; //don't change this from 1st pos
    OzTokens[] ozTokenRegistry;
    address ozDiamond; //check if this is used
    address WETH; 
    address USDC;
    address USDT;

    address swapRouterUni;
    address ethUsdChainlink; //consider removing this since minOut is calculated in the FE

    uint16 defaultSlippage;
    address vaultBalancer;

    address rETH;
    address rEthEthChainlink;

    mapping(address underlying => address token) ozTokens;
    address[] ozTokensArr; //remove - not used
    uint rewardMultiplier; //remove if not used

    address ozBeacon;

    address rocketPoolStorage;
    bytes32 rocketDepositPoolID;
    address rocketVault;
    bytes32 rocketDAOProtocolSettingsDepositID;

    uint24 uniFee; //put here uniFee05 to represent the 0.05% pools
    uint24 uniFee01; //0.01% pool for rETH

    uint24 protocolFee;

    address ozlProxy; //change this to OZL everywhere

    LastRewards rewards; //check where this is used and change the name
    OZLrewards r; //change this to RewardsPackage or not. Check if I'm returning the struct with the mapping (can't be done)

    address adminFeeRecipient; 
    uint16 adminFee; 

    address[] LSDs;

    mapping(address ozToken => uint value) valuePerOzToken;

    address uniFactory;
    address tellorOracle;
    address weETHETHredStone;
    address weETHUSDredStone;

    /**
    * 0 - ozTokenProxy
    * 1 - wozTokenProxy
    */
    address[] ozImplementations;

    BitMaps.BitMap pauseMap; //Do a Pause package for these ones
    uint16 pauseIndexes;
    mapping(address facet => uint index) contractToIndex;
    bool isSwitchEnabled;

    mapping(uint index => Pair pair) tokenPairs;

    //Used in checkDeviation() / ozOracle
    uint16 deviation;

    //Timestampt of last successfull reward applied by chargeOZLfee()
    //Var used for calculating APR
    uint lastRewardStamp;
    uint currAPR;
    uint prevAPR;

    address pendingOwner;
}


struct Pair {
    address base;
    address quote;
    uint24 fee;
}


struct PauseContracts {
    address ozDiamond;
    address ozBeacon;
    address factory;
    address ozlProxy;
}

enum Action {
    OZL_IN,
    OZ_IN,
    OZ_OUT
}


struct AmountsIn {
    uint amountIn;
    uint[] minAmountsOut;
}

struct AmountsOut {
    uint ozAmountIn;
    uint amountInReth;
    uint[] minAmountsOut;
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
    address rEthWethPoolBalancer;
}

struct Oracles {
    address ethUsdChainlink; //fix this vars so the look like Chronicle
    address rEthEthChainlink;
    address tellorOracle;
    address weETHETHredStone;
    address weETHUSDredStone;
}

struct Infra { 
    address ozDiamond;
    address beacon;
    address rocketPoolStorage;
    uint16 defaultSlippage; 
    uint24 uniFee;
    uint24 uniFee01;
    uint24 protocolFee;
    address uniFactory;
    address[] ozImplementations;
    uint16 adminFee;
    uint16 pauseIndexes;
}

//-----

struct LastRewards { //change this struct's name to reflect more what it does
    uint lastBlock;
    uint prevTotalRewards;
}

struct OZLrewards { 
    uint duration;
    uint finishAt; 
    uint updatedAt; 
    uint rewardRate;
    uint rewardPerTokenStored;
    uint circulatingSupply;
    uint recicledSupply;
    mapping(
        address user => uint rewardPerTokenStoredPerUser
    ) userRewardPerTokenPaid;
    mapping(address user => uint rewardsEarned) rewards;
}

struct NewToken {
    string name;
    string symbol;
}

struct OzTokens {
    address ozToken;
    address wozToken;
}

struct BitMap {
    mapping(uint256 => uint256) _data;
}

enum Dir {
    UP,
    DOWN
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

// 4th round -
// rETH        - 116
// totalAssets - 100
// ----
// currentRewards = totalRewards(116 - 100 = 16) - prevTotalRewards(17) = -1


