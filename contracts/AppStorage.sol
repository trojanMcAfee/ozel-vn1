// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


/**
 * @notice Main storage structs
 */
struct AppStorage { 
    //Contracts
    address tricrypto;
    address crvTricrypto; 
    address mimPool;
    address crv2Pool;
    address yTriPool;
    address fraxPool;
    address executor; //6

    //ERC20s
    address USDT;
    address WBTC;
    address USDC;
    address MIM;
    address WETH;
    address FRAX;
    address ETH; //13

    //Token infrastructure
    address oz20; //14
    OZLERC20 oz;

    //System config
    uint protocolFee; //18
    uint defaultSlippage; //19
    mapping(address => bool) tokenDatabase;
    mapping(address => address) tokenL1ToTokenL2;

    //Internal accounting vars
    uint totalVolume; //22
    uint ozelIndex;
    uint feesVault;
    uint failedFees; //25
    mapping(address => uint) usersPayments;
    mapping(address => uint) accountPayments;
    mapping(address => address) accountToUser;
    mapping(address => bool) isAuthorized; //29

    //Curve swaps config
    TradeOps mimSwap; 
    TradeOps usdcSwap; 
    TradeOps fraxSwap; 
    TradeOps[] swaps; //42

    //Mutex locks
    mapping(uint => uint) bitLocks;

    //Stabilizing mechanism (for ozelIndex)
    uint invariant; //44
    uint invariant2;
    uint indexRegulator;
    uint invariantRegulator; //47
    bool indexFlag;
    uint stabilizer;
    uint invariantRegulatorLimit;
    uint regulatorCounter; //51

    //Revenue vars
    ISwapRouter swapRouter; //52
    AggregatorV3Interface priceFeed;
    address revenueToken;
    uint24 poolFee;
    uint[] revenueAmounts; //55

    //Misc vars
    bool isEnabled;
    bool l1Check;
    bytes checkForRevenueSelec;
    address nullAddress; //58

    /*///////////////////////////////////////////////////////////////
                            v1.1 Upgrade
    //////////////////////////////////////////////////////////////*/

    mapping(address => AccData) userToData;
    mapping(bytes4 => bool) authorizedSelectors;

    /*///////////////////////////////////////////////////////////////
                                v1.2
    //////////////////////////////////////////////////////////////*/

    address[] tokenDatabaseArray;

    /*///////////////////////////////////////////////////////////////
                                v2
    //////////////////////////////////////////////////////////////*/

    // AggregatorV3Interface wtiFeed; 
    // AggregatorV3Interface volatilityFeed; //63

    address[] ozTokenRegistry;
    address ozDiamond;
  
}

/// @dev Reference for oz20Facet storage
struct OZLERC20 {
    mapping(address => mapping(address => uint256)) allowances;
    string  name;
    string  symbol;
}

/// @dev Reference for swaps and the addition/removal of account tokens
struct TradeOps {
    int128 tokenIn;
    int128 tokenOut;
    address baseToken;
    address token;  
    address pool;
}

/// @dev Reference for the details of each account
struct AccountConfig { 
    address user;
    address token;
    uint16 slippage; 
    string name;
}

/// @dev Reference to L2 Accounts
struct AccData {
    address[] accounts;
    mapping(bytes32 => bytes32) acc_userToName;
}









