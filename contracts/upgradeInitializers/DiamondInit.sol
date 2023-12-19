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

import {
    AppStorage,
    Tokens,
    Dexes,
    Oracles,
    Infra
} from "../AppStorage.sol";

import {IRocketStorage} from "../interfaces/IRocketPool.sol";

// import "forge-std/console.sol";

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
        Infra memory infra_
    ) external {
        // adding ERC165 data **** COMPLETE this with rest of funcs/interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        //DEXs
        s.swapRouterUni = dexes_.swapRouterUni;
        s.vaultBalancer = dexes_.vaultBalancer;
        s.queriesBalancer = dexes_.queriesBalancer;
        s.rEthWethPoolBalancer = dexes_.rEthWethPoolBalancer;

        //Oracles
        s.ethUsdChainlink = oracles_.ethUsdChainlink;
        s.rEthEthChainlink = oracles_.rEthEthChainlink;

        //Internal infrastructure
        s.ozDiamond = infra_.ozDiamond;
        s.ozBeacon = infra_.beacon;
        s.defaultSlippage = infra_.defaultSlippage;
        s.uniFee = infra_.uniFee;
        s.protocolFee = infra_.protocolFee;

        //ERC20s
        s.WETH = tokens_.weth;
        s.USDC = tokens_.usdc;
        s.USDT = tokens_.usdt;
        s.rETH = tokens_.reth;

        //External infra
        s.rocketPoolStorage = infra_.rocketPoolStorage;
        s.rocketDepositPoolID = keccak256(abi.encodePacked("contract.address", "rocketDepositPool"));
        s.rocketVault = IRocketStorage(s.rocketPoolStorage).getAddress(
            keccak256(abi.encodePacked('contract.address', 'rocketVault'))
        );
        s.rocketDAOProtocolSettingsDepositID = keccak256(abi.encodePacked("contract.address", "rocketDAOProtocolSettingsDeposit"));
        

    }


}
