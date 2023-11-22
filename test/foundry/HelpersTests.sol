// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IPool, IVault} from "../../contracts/interfaces/IBalancer.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import {RequestType, Type, ReqIn, ReqOut} from "./AppStorageTests.sol";
import {ozIDiamond} from "../../contracts/interfaces/ozIDiamond.sol";

import "forge-std/console.sol";



library HelpersTests {

    using FixedPointMathLib for uint;

    function getPermitHash(
        address token_,
        address owner_,
        address spender_,
        uint value_,
        uint nonce_,
        uint deadline_
    ) internal view returns(bytes32) {
        return keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        IERC20Permit(token_).DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner_,
                                spender_,
                                value_,
                                nonce_,
                                deadline_
                            )
                        )
                    )
                );
    }

  

    function _calculateMinAmountOut(
        uint amountIn_,
        uint price_, 
        uint slippage_
    ) internal pure returns(uint minAmountOut) {
        uint ONE_ETHER = 1 ether;

        uint amountOut = amountIn_.fullMulDiv(price_, ONE_ETHER);
        minAmountOut = amountOut - amountOut.fullMulDiv(slippage_, 10000);

    }

    function encodeOutData(uint amountInReth_, ozIDiamond oz_) internal returns(bytes memory data) {
        uint slippage = oz_.getDefaultSlippage();
        uint minAmountOutWeth = _calculateMinAmountOut(amountInReth_, oz_.rETH_ETH(), slippage);
        uint minAmountOutUnderlying = _calculateMinAmountOut(minAmountOutWeth, oz_.ETH_USD(), slippage);
        
        data = abi.encode(amountInReth_, minAmountOutWeth, minAmountOutUnderlying);
    }


    function extract(bytes memory data_) internal pure returns(
        uint[] memory minAmountsOut,
        uint8 v, bytes32 r, bytes32 s
    ) {
        (minAmountsOut, v, r, s) = abi.decode(
            data_, 
            (uint[], uint8, bytes32, bytes32)
        );
    }

   


    function calculateMinAmountsOut( 
        address[2] memory feeds_, 
        uint amountIn_, 
        uint slippage_
    ) internal view returns(uint[] memory) {
        uint[] memory minAmountsOut = new uint[](2);

        for (uint i=0; i < feeds_.length; i++) {            
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = 
                ( i == 0 ? amountIn_ * 1e18 : minAmountsOut[i - 1] )
                .fullMulDiv(1 ether, i == 0 ? uint(price) * 1e10 : uint(price));

            uint minOut = expectedOut - expectedOut.fullMulDiv(slippage_, 10000);
            minAmountsOut[i] = minOut;
        }

        return minAmountsOut;
    }


  






  
    
 


}