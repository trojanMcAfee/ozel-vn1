// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IDiamondCut} from "./IDiamondCut.sol";
import {AmountsIn, AmountsOut, Asset} from "../AppStorage.sol";


interface ozIDiamond {

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;
    function owner() external view returns(address);

    function createOzToken(
        address erc20_,
        string memory name_,
        string memory symbol_
    ) external returns(address);

    function useUnderlying( //remove this
        address underlying_, 
        address user_, 
        AmountsIn memory amounts_
    ) external;

    function useUnderlying( 
        address underlying_, 
        address user_,
        uint amountIn_,
        uint minWethOut_
    ) external;

    function useOzTokens(
        address owner_,
        bytes memory data_
    ) external returns(uint);

    function getDiamondAddr() external view returns(address);
    function rETH_ETH() external returns(uint256); //if not used, removed
    function getDefaultSlippage() external view returns(uint);
    function getUnderlyingValue() external view returns(uint);
    function totalUnderlying(Asset) external view returns(uint);
    function changeDefaultSlippage(uint newBasisPoints_) external;
    function ETH_USD() external view returns(uint);
    function rETH_USD() external view returns(uint);
}