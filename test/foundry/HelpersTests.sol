// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IPool, IVault} from "../../contracts/interfaces/IBalancer.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import {RequestType, Type} from "./AppStorageTests.sol";

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

    function calculateMinAmountsOut(
        address rEthWethPoolBalancer_,
        ozIToken ozERC20_,
        uint ozAmountIn_,
        uint slippage_
    ) internal view returns(uint[] memory) {
        uint bptValue = IPool(rEthWethPoolBalancer_).getRate();

        uint shares = ozERC20_.previewWithdraw(ozAmountIn_);
        uint bptAmountIn = ozERC20_.convertToUnderlying(shares);

        uint amountWethOut = (bptAmountIn * bptValue) / 1 ether;
        uint minWethOut = Helpers.calculateMinAmountOut(amountWethOut, slippage_);
        uint[] memory minAmountsOut = Helpers.convertToDynamic([minWethOut, uint(0), uint(0)]);

        return minAmountsOut;
    }


    function calculateMinAmountsOut(
        address[2] memory feeds_, 
        uint amountIn_, 
        uint decimals_,
        uint slippage_
    ) internal view returns(uint[] memory) {
        uint[] memory minAmountsOut = new uint[](2);
        uint BASE = 18;

        for (uint i=0; i < feeds_.length; i++) {
            uint decimals = decimals_ == BASE ? BASE : (BASE - decimals_) + decimals_;
            
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = 
                ( i == 0 ? amountIn_ * 10 ** (decimals) : minAmountsOut[i - 1] )
                .fullMulDiv(1 ether, i == 0 ? uint(price) * 1e10 : uint(price));

            uint minOut = expectedOut - expectedOut.fullMulDiv(slippage_, 10000);
            minAmountsOut[i] = minOut;
        }

        return minAmountsOut;
    }

    function handleRequestIn(
        bytes memory data_
    ) internal returns(
        RequestType memory req,
        uint[] memory minAmountsOut
    ) {
        (
            address ozERC20Addr,
            uint256 amountIn,
            address ethUsdChainlink,
            address rEthEthChainlink,
            address testToken,
            address wethAddr,
            address rEthWethPoolBalancer,
            address rEthAddr,
            uint256 defaultSlippage
        ) = abi.decode(data_, (
            address,
            uint256,
            address,
            address,
            address,
            address,
            address,
            address,
            uint256
        ));

        ozIToken ozERC20 = ozIToken(ozERC20Addr);

        minAmountsOut = calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], amountIn / 10 ** IERC20Permit(testToken).decimals(), ozERC20.decimals(), defaultSlippage
        );

        (
            address[] memory assets,
            uint[] memory maxAmountsIn,
            uint[] memory amountsIn
        ) = Helpers.convertToDynamics([wethAddr, rEthWethPoolBalancer, rEthAddr], minAmountsOut[1]);

        IVault.JoinPoolRequest memory request = Helpers.createRequest(
            assets, maxAmountsIn, Helpers.createUserData(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0)
        );

        req.join = request;
        req.req = Type.IN;
    }


    function calculateMinAmountsOut(
        uint amount_,
        uint slippage_
    ) internal pure returns(uint) {
        return amount_ - amount_.fullMulDiv(slippage_, 10000);
    }



}