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

import "../AppStorage.sol";
// import "forge-std/console.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit {    

    AppStorage private s;

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init(
        address[] memory registry_,
        address diamond_,
        address swapRouter_,
        address ethUsdChainlink_, 
        address wethAddr_,
        uint defaultSlippage_,
        address vaultBalancer_,
        address queriesBalancer_,
        address rEthAddr_,
        address rEthWethPoolBalancer_,
        address rEthEthChainlink_,
        address beacon_
    ) external {
        // adding ERC165 data **** COMPLETE this with rest of funcs/interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        uint length = registry_.length;
        for (uint i=0; i < length; i++) {
            s.ozTokenRegistry.push(registry_[i]);
        }

        s.ozDiamond = diamond_;
        s.swapRouterUni = swapRouter_;
        s.ethUsdChainlink = ethUsdChainlink_;
        s.WETH = wethAddr_;
        s.defaultSlippage = defaultSlippage_;
        s.vaultBalancer = vaultBalancer_;
        s.queriesBalancer = queriesBalancer_;
        s.rETH = rEthAddr_;
        s.rEthWethPoolBalancer = rEthWethPoolBalancer_;
        s.rEthEthChainlink = rEthEthChainlink_;
        s.ozBeacon = beacon_;
    }


}
