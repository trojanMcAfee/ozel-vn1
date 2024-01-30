// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {ozIDiamond} from "../../contracts/interfaces/ozIDiamond.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {AmountsIn} from "../../contracts/AppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol";


contract Dummy1 {

    ozIToken ozERC20;
    ozIDiamond OZ;


    constructor(address ozToken_, address oz_) {
        ozERC20 = ozIToken(ozToken_);
        OZ = ozIDiamond(oz_);
    }

    function mintOz(address underlying_, uint amountIn_) external returns(bool) {
        bytes memory mintData = OZ.getMintData(
            amountIn_,
            underlying_,
            OZ.getDefaultSlippage(),
            msg.sender
        );

        uint shares = ozERC20.mint(mintData, msg.sender);

        return shares > 0;
    }

}