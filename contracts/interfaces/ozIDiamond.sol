// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IDiamondCut} from "./IDiamondCut.sol";
import {TradeAmounts, TradeAmountsOut, Asset} from "../AppStorage.sol";


interface ozIDiamond {

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;
    function owner() external view returns(address);

    function createOzToken(
        address erc20_,
        string memory name_,
        string memory symbol_
    ) external returns(address);

    function useUnderlying(
        address underlying_, 
        address user_, 
        TradeAmounts memory amounts_
    ) external;

    function useOzTokens(
        TradeAmountsOut memory amts_,
        address ozToken_,
        address owner_,
        address receiver_
    ) external;

    function getDiamondAddr() external view returns(address);
    function rETH_ETH() external returns(uint256); //if not used, removed
    function getRewardMultiplier() external view returns(uint);
    function getUnderlyingValue() external view returns(uint);
    function totalUnderlying(Asset) external view returns(uint);
}