// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import "../../contracts/interfaces/ozIToken.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IQueries, IPool, IAsset, IVault} from "../../contracts/interfaces/IBalancer.sol";
import "../../contracts/libraries/Helpers.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;
    using Helpers for bytes32;
    using Helpers for address;
   

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZ.createOzToken(
            usdcAddr, "Ozel Tether", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint amountIn = 1000 * 10 ** ozUSDC.decimals();
        (uint minWethOut, uint minRethOut) = _calculateMinAmountsOut(amountIn);
        vm.startPrank(owner);

        USDC.approve(address(ozUSDC), amountIn);
        ozUSDC.mint(amountIn, minWethOut, minRethOut);
    }

    //testing createOzToken here and see if it works for minting 
    // a new PT with ozToken.
    //If it works, try minting YT and TT

    function _calculateMinAmountsOut(uint amountIn_) private returns(uint, uint) {
        //Conversion from USDC to WETH
        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        uint expectedOut = amountIn_.fullMulDiv(uint(price) * 10 ** 10, 1 ether);
        uint minOutUnprocessed = 
            expectedOut - expectedOut.fullMulDiv(defaultSlippage * 100, 1000000); 
        uint minWethOut = minOutUnprocessed.mulWad(10 ** 6);
    
        //Conversion from WETH to rETH
        IVault.SingleSwap memory singleSwap = IPool(rEthWethPoolBalancer)
            .getPoolId()
            .createSingleSwap(
                IVault.SwapKind.GIVEN_IN,
                IAsset(wethAddr),
                IAsset(rEthAddr),
                minWethOut
            );

        IVault.FundManagement memory fundMngmt = address(this).createFundMngmt(payable(address(this)));  

        //Queries for minAmountOut for rETH
        uint minRethOut = IQueries(queriesBalancer).querySwap(singleSwap, fundMngmt); //error here <-----
        uint minRethOut = 0;

        return (minWethOut, minRethOut);
    }

}