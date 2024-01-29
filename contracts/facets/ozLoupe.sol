// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {DiamondLoupeFacet} from "./DiamondLoupeFacet.sol";
import {AppStorage, Asset, OZLrewards, AmountsIn} from "../AppStorage.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "../../lib/forge-std/src/interfaces/IERC20.sol";

import "forge-std/console.sol";


contract ozLoupe is DiamondLoupeFacet {

    using FixedPointMathLib for uint;

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

    function quoteAmountsIn(
        uint amountIn_,
        address underlying_,
        uint16 slippage_
    ) public view returns(AmountsIn memory) {
        ozIDiamond OZ = ozIDiamond(address(this));
        uint[] memory minAmountsOut = new uint[](2);

        uint amountIn = IERC20(underlying_).decimals() == 18 ? amountIn_ : amountIn_ * 1e12;
        uint[2] memory prices = [OZ.ETH_USD(), Helpers.rETH_ETH(OZ)];

        uint length = prices.length;
        for (uint i=0; i < length; i++) {
            uint expectedOut = ( i == 0 ? amountIn : minAmountsOut[i - 1] )
                .mulDivDown(1 ether, prices[i]);

            minAmountsOut[i] = expectedOut - expectedOut.mulDivDown(uint(slippage_), 10_000);
        }

        return AmountsIn(amountIn_, minAmountsOut);
    }


    function quoteAmountsOut(
        uint ozAmountIn_,
        address ozToken_,
        uint16 slippage_
    ) public view returns(AmountsOut memory) {
        uint amountInReth = ozERC20_.convertToUnderlying(
            ozIToken(ozToken_).previewWithdraw(ozAmountIn_)
        );

        ozIDiamond OZ = ozIDiamond(address(this));
        uint minAmountOutWeth = amountInReth.calculateMinAmountOut(Helpers.rETH_ETH(OZ), slippage_);
        uint minAmountOutAsset = minAmountOutWeth.calculateMinAmountOut(OZ.ETH_USD(), slippage_);

        uint[] memory minAmountsOut = new uint[](2);
        minAmountsOut[0] = minAmountOutWeth;
        minAmountsOut[1] = minAmountOutAsset;

        return AmountsOut(ozAmountIn_, amountInReth, minAmountsOut);
    }


    function getRedeemData() external view returns(bytes memory) {
        return abi.encode(quoteAmountsOut())
    } //^^^ finish this, substitue these in ozToken.sol - redeem
    //substitue in the tests for redeemin. Test everything


    function getMintData(
        uint amountIn_,
        address underlying_,
        uint16 slippage_,
        address owner_
    ) external view returns(bytes memory) {
        return abi.encode(quoteAmountsIn(amountIn_, underlying_, slippage_), owner_);
    }
   

}