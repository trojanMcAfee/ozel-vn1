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
        console.log('amountIn: ', amountIn);

        uint[] memory minsOut = _calculateMinAmountsOut([ethUsdChainlink, rEthEthChainlink], amountIn);
        _calculateMinOut2(2000, ozUSDC.decimals());
        
        uint minWethOut = minsOut[0];
        uint minRethOut = minsOut[1];
        console.log('minWethOut ***: ', minWethOut);
        console.log('minRethOut: ', minRethOut);

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

        // uint[] memory amountsIn = new uint[](3); //*** */
        // amountsIn[0] = 0;
        // amountsIn[1] = 0;
        // amountsIn[2] = minRethOut;

        uint minAmountBptOut = 0; 

        // console.log('...INIT test');
        // for (uint i=0; i<amountsIn.length; i++) {
        //     console.log('amountsIn', i, amountsIn[i]);
        // }
        // console.log(uint(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT));
        // console.log('joinKind^^^');
        // console.log('minAmountBptOut: ', minAmountBptOut);
        // console.log('...END');

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


        bytes32 poolId = IPool(rEthWethPoolBalancer).getPoolId();

        console.logBytes(request.userData);
        console.log('userData in test ^^^:');

        bytes memory data = hex'00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000079b5ff58f0fd89b';
        request.userData = data; //problem here ***
        
        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            poolId,
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

    function _calculateMinOut(uint amountIn_) private view returns(uint minAmountOut_) {
        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        uint expectedOut = amountIn_.fullMulDiv(uint(price) * 10 ** 10, 1 ether);
        uint minOutUnprocessed = 
            expectedOut - expectedOut.fullMulDiv(defaultSlippage * 100, 1000000); 
        minAmountOut_ = minOutUnprocessed.mulWad(10 ** 6);
        console.log('minOut: ****', minAmountOut_);
    }

    function _calculateMinOut2(uint amountIn_, uint decimals_) private view returns(uint minAmountOut) {
        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();

        // 1 * 1e18 ---- uint(price) * 1e10
        //     x ------- amountIn * 10 ** (decimals == 18 ? 18 : (18 - decimals) + decimals)

        uint expectedOut = ( amountIn_ * 10 ** (decimals_ == 18 ? 18 : (18 - decimals_) + decimals_) ).fullMulDiv(1 ether, uint(price) * 1e10);
        console.log('expectedOut2: ', expectedOut);
        minAmountOut = expectedOut - expectedOut.fullMulDiv(defaultSlippage, 10000);
        console.log('minOut2: ', minAmountOut);

       
    }



    // function calculateSlippage(
    //     uint256 amount_, 
    //     uint256 basisPoint_
    // ) internal pure returns(uint256 minAmountOut) {
        // minAmountOut = amount_ - amount_.mulDivDown(basisPoint_, 10000);
    // }

}