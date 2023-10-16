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

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZ.createOzToken(
            usdcAddr, "Ozel-USDC", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint rawAmount = 1000;
        uint amountIn = rawAmount * 10 ** ozUSDC.decimals();

        uint[] memory minsOut = HelpersTests.calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], rawAmount, ozUSDC.decimals(), defaultSlippage
        );
        
        //------------

        address[] memory assets = Helpers.convertToDynamic([wethAddr, rEthWethPoolBalancer, rEthAddr]);
        uint[] memory maxAmountsIn = Helpers.convertToDynamic([0, 0, minsOut[1]]);
        uint[] memory amountsIn = Helpers.convertToDynamic([0, minsOut[1]]);

        IVault.JoinPoolRequest memory request = Helpers.createRequest(
            assets, maxAmountsIn, Helpers.createUserData(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0)
        );
        
        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            IPool(rEthWethPoolBalancer).getPoolId(),
            owner,
            address(ozDiamond),
            request
        );


        //---------

        vm.startPrank(owner);

        bytes32 permitHash = HelpersTests.getPermitHash(
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
            minWethOut: minsOut[0],
            minRethOut: minsOut[1],
            minBptOut: HelpersTests.calculateMinAmountsOut(bptOut, defaultSlippage)
        });

        ozUSDC.mint(amounts, v, r, s);
    }


    function test_createOzToken2() public {
        ozIToken ozFRAX = ozIToken(OZ.createOzToken(
            fraxAddr, "Ozel-FRAX", "ozFRAX", FRAX.decimals()
        ));
        assertTrue(address(ozFRAX) != address(0));

        uint decimals = ozFRAX.decimals();
        console.log('decimals: ', decimals);


    }


    




}