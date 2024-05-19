// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Helpers} from "../../../contracts/libraries/Helpers.sol";
import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";

import "forge-std/console.sol";


library HelpersLib {

    using FixedPointMathLib for uint;


    function getPermitHashDAI(
        address token_,
        address owner_,
        address spender_,
        uint nonce_,
        uint expiry_,
        bool allowed_
    ) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            IERC20Permit(token_).DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                IERC20Permit(token_).PERMIT_TYPEHASH(),
                owner_,
                spender_,
                nonce_,
                expiry_,
                allowed_))
        ));
    }

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

  
    function calculateMinAmountOut( //check if this can be deleted since i put this func in Helpers.sol also
        uint amountIn_,
        uint price_, 
        uint16 slippage_
    ) internal pure returns(uint minAmountOut) {
        uint amountOut = amountIn_.mulDivDown(price_, 1 ether);
        minAmountOut = amountOut - amountOut.mulDivDown(uint(slippage_), 10000);
    }


    function calculateMinAmountOut(
        uint amountIn_,
        uint16 slippage_
    ) internal pure returns(uint minAmountOut) {
        return amountIn_ - amountIn_.mulDivDown(uint(slippage_), 10000);
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
        uint rawAmountIn_, 
        uint16 slippage_
    ) internal view returns(uint[] memory) {
        uint[] memory minAmountsOut = new uint[](2);

        for (uint i=0; i < feeds_.length; i++) {    
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = 
                ( i == 0 ? rawAmountIn_ * 1e18 : minAmountsOut[i - 1] )
                .mulDivDown(1 ether, i == 0 ? uint(price) * 1e10 : uint(price));

            minAmountsOut[i] = expectedOut - expectedOut.mulDivDown(uint(slippage_), 10000);
        }

        return minAmountsOut;
    }


    function callTest(address addr_, string memory method_) internal {
        (bool success,) = addr_.delegatecall(abi.encodeWithSignature(method_));
        require(success, 'delegatecall() failed');
    }

    function calculateMinAmountsOut(
        uint[2] memory amounts_,
        uint16[2] memory slippages_
    ) internal pure returns(uint[] memory minAmountsOut) {
        uint length = amounts_.length;
        minAmountsOut = new uint[](length);

        for (uint i=0; i<length; i++) {
            minAmountsOut[i] = calculateMinAmountOut(amounts_[i], slippages_[i]);
        }
    }

    function divUp(uint x_, uint y_) internal pure returns(uint) {
        return x_ / y_ + (x_ % y_ == 0 ? 0 : 1);
    }

}