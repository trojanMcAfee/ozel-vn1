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

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;
    using Helpers for bytes32;
    using Helpers for address;
    using TransferHelper for address;
   

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZ.createOzToken(
            usdcAddr, "Ozel Tether", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint amountIn = 1000 * 10 ** ozUSDC.decimals();

        uint[] memory minsOut = _calculateMinAmountsOut([ethUsdChainlink, rEthEthChainlink], 1000, ozUSDC.decimals());
        
        uint minWethOut = minsOut[0];
        uint minRethOut = minsOut[1];

        //------------

        address[] memory assets = new address[](3);
        assets[0] = wethAddr;
        assets[1] = rEthWethPoolBalancer;
        assets[2] = rEthAddr;

        uint[] memory maxAmountsIn = new uint[](3);
        maxAmountsIn[0] = 0;
        maxAmountsIn[1] = 0;
        maxAmountsIn[2] = minRethOut;

        uint[] memory amountsIn = new uint[](2);
        amountsIn[0] = 0;
        amountsIn[1] = minRethOut;


        uint minAmountBptOut = 0; 

        bytes memory userData = abi.encode( 
            IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            minAmountBptOut
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });
        
        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            IPool(rEthWethPoolBalancer).getPoolId(),
            owner,
            address(ozDiamond),
            request
        );

        console.log('bptOut: ', bptOut); 

        //---------

        vm.startPrank(owner);
        USDC.approve(address(ozUSDC), amountIn);
        ozUSDC.mint(amountIn, minWethOut, minRethOut);
    }

    //testing createOzToken here and see if it works for minting 
    // a new PT with ozToken.
    //If it works, try minting YT and TT


    function _calculateMinAmountsOut(address[2] memory feeds_, uint amountIn_, uint decimals_) private view returns(uint[] memory) {
        uint[] memory minAmountsOut = new uint[](2);

        //---------

    //     (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();

    //     uint expectedOut = ( amountIn_ * 10 ** (decimals_ == 18 ? 18 : (18 - decimals_) + decimals_) ).fullMulDiv(1 ether, uint(price) * 1e10);
    //     uint minAmountOut2 = expectedOut - expectedOut.fullMulDiv(defaultSlippage, 10000);
    //     minAmountsOut[0] = minAmountOut2;
    //     console.log('minOut - eth: ', minAmountOut2);


    //     (,price,,,) = AggregatorV3Interface(rEthEthChainlink).latestRoundData();
    //     expectedOut = minAmountOut2 .fullMulDiv(1 ether, uint(price));
    //     uint minAmountOut = expectedOut - expectedOut.fullMulDiv(defaultSlippage, 10000);
    //     console.log('minOut - rETH: ', minAmountOut);
    //     minAmountsOut[1] = minAmountOut;

    //    return minAmountsOut;

       //--------
        for (uint i=0; i < feeds_.length; i++) {
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = 
                ( i == 0 ? amountIn_ * 10 ** (decimals_ == 18 ? 18 : (18 - decimals_) + decimals_) : minAmountsOut[i - 1] )
                .fullMulDiv(1 ether, i == 0 ? uint(price) * 1e10 : uint(price));

            uint minOut = expectedOut - expectedOut.fullMulDiv(defaultSlippage, 10000);
            minAmountsOut[i] = minOut;
            console.log('minOut : ', i, minAmountsOut[i]);
        }

        return minAmountsOut;
    }





}