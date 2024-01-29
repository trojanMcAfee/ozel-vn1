// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Dummy1 {

    ozIToken ozToken;
    ozIDiamond OZ;

    address ethUsdChainlink;
    address rEthEthChainlink;

    constructor(address ozToken_, address oz_) {
        ozToken = ozIToken(ozToken_);
        OZ = oz_;
    }

    function mintOz(address underlying_, uint amountIn_) external returns(bool) {
        uint[] memory minAmountsOut = HelpersLib.calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], amountIn_ / 10 ** IERC20Permit(token_).decimals(), OZ.getDefaultSlippage()
        );
        
        AmountsIn memory amounts = AmountsIn(
            amountIn,
            minAmountsOut
        );

        bytes memory data = abi.encode(amounts, msg.sender);

        IERC20(underlying_).approve(address(OZ), amountIn_);

        OZ.mint(data);

    }

}