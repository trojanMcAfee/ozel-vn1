// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

enum FacetCutAction {Add, Replace, Remove}

interface ozIDiamond {

    function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external;
    function getOzelIndex() external view returns(uint256);
    function getProtocolFee() external view returns(uint256);
    function depositFeesInDeFi(uint256 fee_, bool isRetry_) external;
    function getFeesVault() external view returns(uint256);
    function getAUM() external view returns(uint256 wethUM, uint256 valueUM);

    /*///////////////////////////////////////////////////////////////
                                v2
    //////////////////////////////////////////////////////////////*/

    function createOzToken(address erc20_, uint amount_) external view returns(address);



}