// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IAave } from "../interfaces/IAave.sol";

import {
    AppStorage,
    Tokens,
    Dexes,
    Oracles,
    Infra,
    PauseContracts,
    Pair
} from "../AppStorage.sol";

import {IRocketStorage} from "../interfaces/IRocketPool.sol";

import "forge-std/console.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit {    

    AppStorage private s;

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init(
        Tokens memory tokens_,
        Dexes memory dexes_,
        Oracles memory oracles_,
        Infra memory infra_,
        PauseContracts memory pause_
    ) external {
        // adding ERC165 data **** COMPLETE this with rest of funcs/interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        //Money markets
        s.swapRouterUni = dexes_.swapRouterUni;
        s.vaultBalancer = dexes_.vaultBalancer;
        s.rEthWethPoolBalancer = dexes_.rEthWethPoolBalancer;
        s.poolProviderAave = dexes_.poolProviderAave;

        //Oracles
        s.ethUsdChainlink = oracles_.ethUsdChainlink;
        s.rEthEthChainlink = oracles_.rEthEthChainlink;
        s.tellorOracle = oracles_.tellorOracle;
        s.weETHETHredStone = oracles_.weETHETHredStone;
        s.weETHUSDredStone = oracles_.weETHUSDredStone;

        //Internal infrastructure
        s.ozDiamond = infra_.ozDiamond;
        s.ozBeacon = infra_.beacon;
        s.defaultSlippage = infra_.defaultSlippage;
        s.uniFee = infra_.uniFee;
        s.uniFee01 = infra_.uniFee01;
        s.protocolFee = infra_.protocolFee;
        s.uniFactory = infra_.uniFactory;
        s.adminFee = infra_.adminFee;
        s.adminFeeRecipient = ds.contractOwner;

        //ERC20s
        s.WETH = tokens_.weth;
        s.USDC = tokens_.usdc;
        s.USDT = tokens_.usdt;
        s.rETH = tokens_.reth;
        s.aUSDC = tokens_.ausdc;

        //LSDs + WETH
        s.LSDs.push(s.rETH);
        s.LSDs.push(s.WETH);

        //External infra
        s.rocketPoolStorage = infra_.rocketPoolStorage;
        s.rocketDepositPoolID = keccak256(abi.encodePacked("contract.address", "rocketDepositPool"));
        s.rocketVault = IRocketStorage(s.rocketPoolStorage).getAddress(
            keccak256(abi.encodePacked('contract.address', 'rocketVault'))
        );
        s.rocketDAOProtocolSettingsDepositID = keccak256(abi.encodePacked("contract.address", "rocketDAOProtocolSettingsDeposit"));
        
        //Sets up ozBeacon implementations
        uint length = infra_.ozImplementations.length;
        for (uint i=0; i<length; i++) {
            s.ozImplementations.push(infra_.ozImplementations[i]);
        }

        //Pause system variables
        s.pauseIndexes = infra_.pauseIndexes;
        s.contractToIndex[pause_.ozDiamond] = 2;
        s.contractToIndex[pause_.ozBeacon] = 3;
        s.contractToIndex[pause_.factory] = 4; //change this to contractToIndex and everywhere
        s.contractToIndex[pause_.ozlProxy] = 5;

        //Enables checks for paused system and/or sections
        s.isSwitchEnabled = true;

        //Combinations of tokens used for pairs on Uniswap oracle
        s.tokenPairs[0] = Pair(s.rETH, s.WETH, s.uniFee);
        s.tokenPairs[1] = Pair(s.rETH, s.WETH, s.uniFee01);
        s.tokenPairs[2] = Pair(s.WETH, s.USDC, s.uniFee);  //<--- put these in Setup.sol

        s.deviation = 100; //<---- put this in Setup.sol

        // IAave(s.poolProviderAave).setUserEMode(1);

        s.rewardsStartTime = block.timestamp;
        s.EPOCH = 7 days; 

    }


}
