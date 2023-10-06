// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IDiamondCut} from "./IDiamondCut.sol";


interface ozIDiamond {

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;
    function owner() external view returns(address);

    function createOzToken(
        address erc20_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external returns(address);

    function useUnderlying(address underlying_, address user_, uint minWethOut_, uint minRethOut_) external;
    function getDiamondAddr() external view returns(address);


}