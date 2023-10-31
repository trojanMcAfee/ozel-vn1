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
    DiamondInfra
} from "../AppStorage.sol";
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
        DiamondInfra memory infra_
    ) external {
        // adding ERC165 data **** COMPLETE this with rest of funcs/interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        //Create ERC20 registry
        address[] memory registry = new address[](1);
        registry[0] = tokens_.usdt;

        uint length = registry.length;
        for (uint i=0; i < length; i++) {
            s.ozTokenRegistry.push(registry[i]);
        }

        // s.ozDiamond = diamond_;
        s.ozDiamond = infra_.ozDiamond;

        // s.swapRouterUni = swapRouter_;
        s.swapRouterUni = dexes_.swapRouterUni;

        // s.ethUsdChainlink = ethUsdChainlink_;
        s.ethUsdChainlink = oracles_.ethUsdChainlink;

        // s.WETH = wethAddr_;
        s.WETH = tokens_.weth;

        // s.defaultSlippage = defaultSlippage_;
        s.defaultSlippage = infra_.defaultSlippage;

        // s.vaultBalancer = vaultBalancer_;
        s.vaultBalancer = dexes_.vaultBalancer;

        // s.queriesBalancer = queriesBalancer_;
        s.queriesBalancer = dexes_.vaultBalancer;

        // s.rETH = rEthAddr_;
        s.rETH = tokens_.reth;

        // s.rEthWethPoolBalancer = rEthWethPoolBalancer_;
        s.rEthWethPoolBalancer = dexes_.rEthWethPoolBalancer;

        // s.rEthEthChainlink = rEthEthChainlink_;
        s.rEthEthChainlink = oracles_.rEthEthChainlink;

        // s.ozBeacon = beacon_;
        s.ozBeacon = infra_.beacon;

        // s.USDC = usdcAddr_;
        s.USDC = tokens_.usdc;

        s.USDT = tokens_.usdt;

    }


}
