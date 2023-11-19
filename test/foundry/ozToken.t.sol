// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IQueries, IPool, IAsset, IVault} from "../../contracts/interfaces/IBalancer.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {AmountsIn, AmountsOut} from "../../contracts/AppStorage.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersTests} from "./HelpersTests.sol";
// import "solady/src/utils/FixedPointMathLib.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {Type, RequestType, ReqIn, ReqOut} from "./AppStorageTests.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {ozToken} from "../../contracts/ozToken.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "forge-std/console.sol";



contract ozTokenTest is Setup {

    using FixedPointMathLib for uint;


    /**
     * Mints a small quantity of ozUSDC (~100)
     */
    function test_minting_approve_smallMint() public {
        //Pre-condition
        uint rawAmount = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }
}