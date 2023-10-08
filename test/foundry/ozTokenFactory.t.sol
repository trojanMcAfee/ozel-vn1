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
        uint[] memory minsOut = _calculateMinAmountsOut([ethUsdChainlink, rEthEthChainlink], amountIn);
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

        bytes memory userData = abi.encode( 
            IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            0
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        console.log('hiiii ****');

        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            IPool(rEthWethPoolBalancer).getPoolId(),
            address(ozDiamond),
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

    function _calculateMinAmountsOut(
        address[2] memory feeds_, 
        uint amountIn_
    ) private view returns(uint[] memory minAmountsOut) {
        minAmountsOut = new uint[](2);

        for (uint i=0; i < feeds_.length; i++) {
            (,int price,,,) = AggregatorV3Interface(feeds_[i]).latestRoundData();
            uint expectedOut = (i == 0 ? amountIn_ : minAmountsOut[0]).fullMulDiv(uint(price) * 10 ** 10, 1 ether);
            uint minOutUnprocessed = 
                expectedOut - expectedOut.fullMulDiv(defaultSlippage * 100, 1000000); 
            minAmountsOut[i] = minOutUnprocessed.mulWad(10 ** 6);
        }
    }

}