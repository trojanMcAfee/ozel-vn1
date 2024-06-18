// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {ozIDiamond} from "../../../contracts/interfaces/ozIDiamond.sol";


//Contract used to simulate minting/redeeming on behalf of an ozToken holder.
contract Dummy1 {

    ozIToken ozERC20;
    ozIDiamond OZ;


    constructor(address ozToken_, address oz_) {
        ozERC20 = ozIToken(ozToken_);
        OZ = ozIDiamond(oz_);
    }

    function mintOz(uint amountIn_) external returns(bool) {
        bytes memory mintData = OZ.getMintData(
            amountIn_,
            OZ.getDefaultSlippage(),
            msg.sender,
            address(ozERC20)
        );

        uint shares = ozERC20.mint(mintData, msg.sender);

        return shares > 0;
    }

    function redeemOz(uint ozAmountIn_) external returns(bool) {
        bytes memory redeemData = OZ.getRedeemData(
            ozAmountIn_,
            address(ozERC20),
            OZ.getDefaultSlippage(),
            msg.sender,
            msg.sender
        );

        uint amountAssetOut = ozERC20.redeem(redeemData, msg.sender);
        
        return amountAssetOut > 0;
    }

}