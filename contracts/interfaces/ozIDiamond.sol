// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IDiamondCut} from "./IDiamondCut.sol";
import {TradeAmounts} from "../AppStorage.sol";


interface ozIDiamond {

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;
    function owner() external view returns(address);

    function createOzToken(
        address erc20_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external returns(address);

    function useUnderlying(
        address underlying_, 
        address user_, 
        address receiver_,
        TradeAmounts memory amounts_
    ) external;

    function getDiamondAddr() external view returns(address);
    function rETH_ETH() external returns(uint256); //if not used, removed
    function getRewardMultiplier() external view returns(uint);
}