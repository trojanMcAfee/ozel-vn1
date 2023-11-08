// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {DiamondCutFacet} from "./DiamondCutFacet.sol";
import {AppStorage} from "../AppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

import "forge-std/console.sol";


contract ozCut is DiamondCutFacet {

    AppStorage private s;

    function changeDefaultSlippage(uint newBasisPoints_) external {
        LibDiamond.enforceIsContractOwner();
        s.defaultSlippage = newBasisPoints_;
    }


}