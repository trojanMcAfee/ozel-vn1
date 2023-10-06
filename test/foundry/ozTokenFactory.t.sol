// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import "../../contracts/interfaces/ozIToken.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;

    enum MinOut {
        UNISWAP,
        BALANCER
    }
   

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZ.createOzToken(
            usdcAddr, "Ozel Tether", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint amountIn = 1000 * 10 ** ozUSDC.decimals();
        uint minAmountOut = _calculateMinOut(amountIn);
        vm.startPrank(owner);

        USDC.approve(address(ozUSDC), amountIn);
        ozUSDC.mint(amountIn, minAmountOut);
    }

    //testing createOzToken here and see if it works for minting 
    // a new PT with ozToken.
    //If it works, try minting YT and TT

    function _calculateMinOut(uint amountIn_, MinOut protocol_) private view returns(uint minAmountOut_) {
        if (protocol_ == MinOut.UNISWAP) {
            (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
            uint expectedOut = amountIn_.fullMulDiv(uint(price) * 10 ** 10, 1 ether);
            uint minOutUnprocessed = 
                expectedOut - expectedOut.fullMulDiv(defaultSlippage * 100, 1000000); 
            minAmountOut_ = minOutUnprocessed.mulWad(10 ** 6);
        } else if (protocol_ == MinOUT == BALANCER) {
            IQueries(queriesBalancer).blabla
        }
    }

}