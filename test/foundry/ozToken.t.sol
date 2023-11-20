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

    uint constant ONE_ETHER = 1 ether;


    /**
     * Mints a small quantity of ozUSDC (~100)
     */
    function test_minting_approve_smallMint() public {
        //Pre-condition
        uint rawAmount = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //Action
        // (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
        //     testToken, amountIn, alice, ALICE_PK, true, false
        // );
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(testToken, "Ozel-ERC20", "ozERC20"));
        
        vm.startPrank(alice);

        bytes memory data = abi.encode(amountIn, _calculateMinWethOut(amountIn), alice);
        
        //------
        // address rocketDAOProtocolSettingsDeposit = 0xac2245BE4C2C1E9752499Bcd34861B761d62fC27;
        // bytes32 settingNameSpace = vm.load(rocketDAOProtocolSettingsDeposit, bytes32(1));

        // vm.store(rocketDAOProtocolSettingsDeposit, bytes32(1), );


        //modify the value where the maxDeposit is so i can run tests 

        //-------


        IERC20Permit(testToken).approve(address(ozDiamond), amountIn);
        ozERC20.mint(data); 

        vm.stopPrank();


        //Post-conditions
        // assertTrue(address(ozERC20) != address(0));
        // assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }


    /**
     * HELPERS
     */

    //Modify this so it can handle tokens with other decimals besides 8
    function _calculateMinWethOut(uint amountIn_) internal view returns(uint minOut) {
        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        uint expectedOut = amountIn_.mulDivDown(uint(price) * 1e10, ONE_ETHER);
        minOut = expectedOut - expectedOut.mulDivDown(OZ.getDefaultSlippage(), 10000);
    }


    //  function _createAndMintOzTokens(
    //     address testToken_,
    //     uint amountIn_, 
    //     address user_, 
    //     uint userPk_,
    //     bool create_,
    //     bool is2612_
    // ) private returns(ozIToken ozERC20, uint shares) {
    //     if (create_) {
    //         ozERC20 = ozIToken(OZ.createOzToken(
    //             testToken_, "Ozel-ERC20", "ozERC20"
    //         ));
    //     } else {
    //         ozERC20 = ozIToken(testToken_);
            
    //     }

    //     (
    //         RequestType memory req,
    //         uint8 v, bytes32 r, bytes32 s
    //     ) = _createDataOffchain(ozERC20, amountIn_, userPk_, user_, Type.IN);

    //     vm.startPrank(user_);

    //     if (is2612_) {
    //         IERC20Permit(testToken).permit(
    //             user_, 
    //             address(ozDiamond), 
    //             req.amtsIn.amountIn, 
    //             block.timestamp, 
    //             v, r, s
    //         );
    //     } else {
    //         IERC20Permit(testToken).approve(address(ozDiamond), req.amtsIn.amountIn);
    //     }

    //     shares = ozERC20.mint(req.amtsIn, user_); 
    //     vm.stopPrank();
    // }

    // function _createDataOffchain( 
    //     ozIToken ozERC20_, 
    //     uint amountIn_,
    //     uint SENDER_PK_,
    //     address sender_,
    //     Type reqType_
    // ) private returns( 
    //     RequestType memory req,
    //     uint8 v, bytes32 r, bytes32 s
    // ) {
    //     uint[] memory minAmountsOut;
    //     uint bptAmountIn;

    //     if (reqType_ == Type.OUT) {
    //         bytes memory data = _getBytesReqOut(address(ozERC20_), amountIn_);

    //         (
    //             RequestType memory reqInternal,
    //             uint[] memory minAmountsOutInternal,
    //             uint bptAmountInternal
    //         ) = HelpersTests.handleRequestOut(data);

    //         minAmountsOut = minAmountsOutInternal;
    //         req = reqInternal;
    //         bptAmountIn = bptAmountInternal;
    //     } else if (reqType_ == Type.IN) { 
    //         bytes memory data = _getBytesReqIn(address(ozERC20_), amountIn_);

    //         (
    //             RequestType memory reqInternal,
    //             uint[] memory minAmountsOutInternal
    //         ) = HelpersTests.handleRequestIn(data);

    //         minAmountsOut = minAmountsOutInternal;
    //         req = reqInternal;
    //     }

    //     (uint amountOut, bytes32 permitHash) = _getHashNAmountOut(sender_, req, amountIn_);

    //     (v, r, s) = vm.sign(SENDER_PK_, permitHash);

    //     req = _createRequestType(reqType_, amountOut, amountIn_, bptAmountIn, minAmountsOut);
    // }
}