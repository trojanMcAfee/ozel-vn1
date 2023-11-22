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

    // function calculateMinAmountsOut(
    //     address rEthWethPoolBalancer_,
    //     ozIToken ozERC20_,
    //     uint ozAmountIn_,
    //     uint slippage_
    // ) internal view returns(uint[] memory) {
    //     uint bptValue = IPool(rEthWethPoolBalancer_).getRate();

    //     uint shares = ozERC20_.previewWithdraw(ozAmountIn_);
    //     uint bptAmountIn = ozERC20_.convertToUnderlying(shares);

    //     uint amountWethOut = (bptAmountIn * bptValue) / 1 ether;
    //     uint minWethOut = Helpers.calculateMinAmountOut(amountWethOut, slippage_);
    //     uint[] memory minAmountsOut = Helpers.convertToDynamic([minWethOut, uint(0), uint(0)]);

    //     return minAmountsOut;
    // }

    function calculateMinAmountOut(
        uint amountIn_,
        uint price_, 
        uint slippage_
    ) internal view returns(uint minAmountOut) {
        uint ONE_ETHER = 1 ether;

        uint amountOut = amountIn_.fullMulDiv(price_, ONE_ETHER);
        minAmountOut = amountOut - amountOut.fullMulDiv(slippage_, 10000);

        // uint amountOutWeth = amountInReth.mulDiv(OZ.rETH_ETH(), ONE_ETHER);
        // uint minAmountOutWeth = HelpersTests.calculateMinAmountsOut(amountOutWeth, OZ.getDefaultSlippage());

        // uint amountOutUnderlying = minAmountOutWeth.mulDiv(OZ.ETH_USD(), ONE_ETHER);
        // uint minAmountOutUnderlying = HelpersTests.calculateMinAmountsOut(amountOutUnderlying, OZ.getDefaultSlippage());
    }

    function encodeOutData(uint amountInReth_, ozIDiamond oz_) internal returns(bytes memory data) {
        uint slippage = oz_.getDefaultSlippage();
        uint minAmountOutWeth = calculateMinAmountOut(amountInReth_, oz_.rETH_ETH(), slippage);
        uint minAmountOutUnderlying = calculateMinAmountOut(minAmountOutWeth, oz_.ETH_USD(), slippage);
        
        data = abi.encode(amountInReth_, minAmountOutWeth, minAmountOutUnderlying);
    }


    function extract(bytes memory data_) internal returns(
        uint[] memory minAmountsOut,
        uint8 v, bytes32 r, bytes32 s
    ) {
        (minAmountsOut, v, r, s) = abi.decode(
            data_, 
            (uint[], uint8, bytes32, bytes32)
        );
    }

    // function encodeOutData(ozIToken ozERC20_, uint amountIn_, ozIDiamond oz_) internal returns(bytes memory data) {
    //     uint shares = ozERC20_.previewWithdraw(amountIn_);
    //     uint amountInReth = ozERC20_.convertToUnderlying(shares);

    //     uint slippage = oz_.getDefaultSlippage();
    //     uint minAmountOutWeth = calculateMinAmountOut(amountInReth, oz_.rETH_ETH(), slippage);
    //     uint minAmountOutUnderlying = calculateMinAmountOut(minAmountOutWeth, oz_.ETH_USD(), slippage);
        
    //     data = abi.encode(amountInReth, minAmountOutWeth, minAmountOutUnderlying);
    // }


    // function encodeInData(
    //     address[2] memory feeds_,
    //     address testToken_,
    //     uint amountIn_,
    //     uint slippage_,
    // ) internal pure returns(bytes memory) {
    //     uint[] memory minAmountsOut = calculateMinAmountsOut(
    //         feeds_, amountIn_ / 10 ** IERC20Permit(testToken_).decimals(), 18, slippage_
    //     );

        
    // }


    // function encodeInData(
    //     uint[] memory minAmountsOut_,
    //     address sender_,
    //     address testToken_,
    //     address ozDiamond_,
    //     uint amountIn_,
    //     uint SENDER_PK_
    // ) internal returns(bytes memory data) {
    //     bytes32 permitHash = getPermitHash(
    //         testToken_,
    //         sender_,
    //         ozDiamond_,
    //         amountIn_,
    //         IERC20Permit(testToken_).nonces(sender_),
    //         block.timestamp
    //     );

    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(SENDER_PK_, permitHash);
    //     data = abi.encode(minAmountsOut_, v, r, s);
    // }



    function calculateMinAmountsOut( 
        address[2] memory feeds_, 
        uint amountIn_, 
        uint slippage_
    ) internal view returns(uint[] memory) {
        uint[] memory minAmountsOut = new uint[](2);
        uint BASE = 18;

        for (uint i=0; i < feeds_.length; i++) {            
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = 
                ( i == 0 ? amountIn_ * 10 ** 18 : minAmountsOut[i - 1] )
                .fullMulDiv(1 ether, i == 0 ? uint(price) * 1e10 : uint(price));

            uint minOut = expectedOut - expectedOut.fullMulDiv(slippage_, 10000);
            minAmountsOut[i] = minOut;
        }

        return minAmountsOut;
    }


    // function handleRequestOut(bytes memory data_) internal view returns(
    //     RequestType memory req,
    //     uint[] memory minAmountsOut,
    //     uint bptAmountIn
    // ) {

    //     (ReqOut memory reqOut) = abi.decode(data_, (ReqOut));

    //     ozIToken ozERC20 = ozIToken(reqOut.ozERC20Addr);

    //     address[] memory assets = Helpers.convertToDynamic([reqOut.wethAddr, reqOut.rEthWethPoolBalancer, reqOut.rEthAddr]);

    //     minAmountsOut = HelpersTests.calculateMinAmountsOut(
    //         reqOut.rEthWethPoolBalancer, ozERC20, reqOut.amountIn, reqOut.defaultSlippage
    //     );

    //     uint shares = ozERC20.previewWithdraw(reqOut.amountIn);
    //     bptAmountIn = ozERC20.convertToUnderlying(shares);

    //     IVault.ExitPoolRequest memory request = Helpers.createExitRequest(
    //         assets, minAmountsOut, Helpers.createUserData(IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, 0)
    //     );

    //     req.exit = request;
    //     req.req = Type.OUT;
    // }


    // function handleRequestIn(
    //     bytes memory data_
    // ) internal view returns(
    //     RequestType memory req,
    //     uint[] memory minAmountsOut
    // ) {
    //     (ReqIn memory reqIn) = abi.decode(data_, (ReqIn));

    //     ozIToken ozERC20 = ozIToken(reqIn.ozERC20Addr);

    //     minAmountsOut = calculateMinAmountsOut(
    //         [reqIn.ethUsdChainlink, reqIn.rEthEthChainlink], reqIn.amountIn / 10 ** IERC20Permit(reqIn.testToken).decimals(), ozERC20.decimals(), reqIn.defaultSlippage
    //     );

    //     (
    //         address[] memory assets,
    //         uint[] memory maxAmountsIn,
    //         uint[] memory amountsIn
    //     ) = Helpers.convertToDynamics([reqIn.wethAddr, reqIn.rEthWethPoolBalancer, reqIn.rEthAddr], minAmountsOut[1]);

    //     IVault.JoinPoolRequest memory request = Helpers.createRequest(
    //         assets, maxAmountsIn, Helpers.createUserData(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0)
    //     );

    //     req.join = request;
    //     req.req = Type.IN;
    // }


    function calculateMinAmountsOut(
        uint amount_,
        uint slippage_
    ) internal pure returns(uint) {
        return amount_ - amount_.fullMulDiv(slippage_, 10000);
    }


    /**
     * ***** L1 *****
     */
    
    // function compress(
    //     uint112 amountIn_, 
    //     uint112 minWethOut_, 
    //     address receiver_
    // ) internal returns(bytes32) {
    //     abi.encodePacked(amountIn);
    // }


}