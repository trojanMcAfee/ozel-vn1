// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import "../../contracts/interfaces/ozIToken.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IQueries, IPool, IAsset, IVault} from "../../contracts/interfaces/IBalancer.sol";
import "../../contracts/libraries/Helpers.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {TradeAmounts} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;
    using Helpers for bytes32;
    using Helpers for address;
    using TransferHelper for address;
    //----
    using Helpers for address[3];
    using Helpers for uint[3];
    using Helpers for uint[2];
    using Helpers for IVault.JoinKind;
    using Helpers for address[];
   

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZ.createOzToken(
            usdcAddr, "Ozel Tether", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint rawAmount = 1000;
        uint amountIn = rawAmount * 10 ** ozUSDC.decimals();

        uint[] memory minsOut = _calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], rawAmount, ozUSDC.decimals()
        );
        
        uint minWethOut = minsOut[0];
        uint minRethOut = minsOut[1];

        //------------

        address[] memory assets = [wethAddr, rEthWethPoolBalancer, rEthAddr].convertToDynamic();
        uint[] memory maxAmountsIn = [0, 0, minRethOut].convertToDynamic();
        uint[] memory amountsIn = [0, minRethOut].convertToDynamic();

        // bytes memory userData = abi.encode( 
        //     IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
        //     amountsIn,
        //     0
        // );

        // IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
        //     assets: assets,
        //     maxAmountsIn: maxAmountsIn,
        //     userData: userData,
        //     fromInternalBalance: false
        // });

        IVault.JoinPoolRequest memory request = assets.createRequest(
            maxAmountsIn, IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT.createUserData(amountsIn, 0)
        );
        
        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            IPool(rEthWethPoolBalancer).getPoolId(),
            owner,
            address(ozDiamond),
            request
        );

        uint minBptOut = _calculateMinAmountsOut(bptOut);

        //---------

        vm.startPrank(owner);

        bytes32 permitHash = _getPermitHash(
            usdcAddr,
            owner,
            address(ozDiamond),
            amountIn,
            USDC.nonces(owner),
            block.timestamp
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PK, permitHash);

        TradeAmounts memory amounts = TradeAmounts({
            amountIn: amountIn,
            minWethOut: minWethOut,
            minRethOut: minRethOut,
            minBptOut: minBptOut
        });

        ozUSDC.mint(amounts, v, r, s);
    }


    /**
     * Helpers 
     */
   
    function _getPermitHash(
        address token_,
        address owner_,
        address spender_,
        uint value_,
        uint nonce_,
        uint deadline_
    ) private view returns(bytes32) {
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


    function _calculateMinAmountsOut(
        address[2] memory feeds_, 
        uint amountIn_, 
        uint decimals_
    ) private view returns(uint[] memory) {
        uint[] memory minAmountsOut = new uint[](2);

        for (uint i=0; i < feeds_.length; i++) {
            uint decimals = decimals_ == _BASE ? _BASE : (_BASE - decimals_) + decimals_;
            
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = 
                ( i == 0 ? amountIn_ * 10 ** (decimals) : minAmountsOut[i - 1] )
                .fullMulDiv(1 ether, i == 0 ? uint(price) * 1e10 : uint(price));

            uint minOut = expectedOut - expectedOut.fullMulDiv(defaultSlippage, 10000);
            minAmountsOut[i] = minOut;
        }

        return minAmountsOut;
    }


    function _calculateMinAmountsOut(
        uint256 amount_
    ) private view returns(uint256 minAmountOut) {
        minAmountOut = amount_ - amount_.fullMulDiv(defaultSlippage, 10000);
    }



}