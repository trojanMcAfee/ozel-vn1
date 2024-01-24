// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {DiamondLoupeFacet} from "./DiamondLoupeFacet.sol";
import {AppStorage, Asset, OZLrewards} from "../AppStorage.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";

import "forge-std/console.sol";


contract ozLoupe is DiamondLoupeFacet {

    AppStorage private s;

    function getDefaultSlippage() external view returns(uint16) {
        return s.defaultSlippage;
    }


    function totalUnderlying(Asset type_) public view returns(uint total) {
        total = IERC20Permit(s.rETH).balanceOf(address(this));
        if (type_ == Asset.USD) total = (total * ozIDiamond(s.ozDiamond).rETH_USD()) / 1 ether;  
    }


    function getProtocolFee() external view returns(uint) {
        return uint(s.protocolFee);
    }

    function ozTokens(address underlying_) external view returns(address) {
        return s.ozTokens[underlying_];
    }

    function getLSDs() external view returns(address[] memory) {
        return s.LSDs;
    }

    // function getRewardsData() external view returns(OZLrewards memory) {
    //     return s.r;
    // }
   

}