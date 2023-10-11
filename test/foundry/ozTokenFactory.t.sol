// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
// import "solady/src/utils/FixedPointMathLib.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IQueries, IPool, IAsset, IVault} from "../../contracts/interfaces/IBalancer.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {TradeAmounts} from "../../contracts/AppStorage.sol";
import {HelpersTests} from "./HelpersTests.sol";

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
    //-----
    using HelpersTests for address;
    using HelpersTests for address[2];
    using HelpersTests for uint;
   

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZ.createOzToken(
            usdcAddr, "Ozel Tether", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint rawAmount = 1000;
        uint amountIn = rawAmount * 10 ** ozUSDC.decimals();

        uint[] memory minsOut = [ethUsdChainlink, rEthEthChainlink].calculateMinAmountsOut(
            rawAmount, ozUSDC.decimals(), defaultSlippage
        );
        
        uint minWethOut = minsOut[0];
        uint minRethOut = minsOut[1];

        //------------

        address[] memory assets = [wethAddr, rEthWethPoolBalancer, rEthAddr].convertToDynamic();
        uint[] memory maxAmountsIn = [0, 0, minRethOut].convertToDynamic();
        uint[] memory amountsIn = [0, minRethOut].convertToDynamic();

        IVault.JoinPoolRequest memory request = assets.createRequest(
            maxAmountsIn, IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT.createUserData(amountsIn, 0)
        );
        
        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            IPool(rEthWethPoolBalancer).getPoolId(),
            owner,
            address(ozDiamond),
            request
        );

        uint minBptOut = bptOut.calculateMinAmountsOut(defaultSlippage);

        //---------

        vm.startPrank(owner);

        bytes32 permitHash = usdcAddr.getPermitHash(
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


    




}