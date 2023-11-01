// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
// import "solady/src/utils/FixedPointMathLib.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IQueries, IPool, IAsset, IVault} from "../../contracts/interfaces/IBalancer.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {TradeAmounts, TradeAmountsOut} from "../../contracts/AppStorage.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersTests} from "./HelpersTests.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {Type, RequestType, ReqIn, ReqOut} from "./AppStorageTests.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;

    // enum Type {
    //     IN,
    //     OUT
    // }

    // struct RequestType {
    //     IVault.JoinPoolRequest join;
    //     IVault.ExitPoolRequest exit;
    //     TradeAmounts amtsIn;
    //     TradeAmountsOut amtsOut;
    //     Type req;
    // }


    function test_minting() public {
        /**
         * Pre-conditions + Actions (creating of ozTokens)
         */
        uint rawAmount = 100;
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true
        );

        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesBob) = _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false
        );

        amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
        assertTrue(sharesAlice / 2 == sharesBob);
        assertTrue(sharesAlice / 4 == sharesCharlie);
        assertTrue(sharesBob == sharesCharlie * 2);
        assertTrue(sharesBob / 2 == sharesCharlie);

        uint balanceAlice = ozERC20.balanceOf(alice);
        uint balanceBob = ozERC20.balanceOf(bob);
        uint balanceCharlie = ozERC20.balanceOf(charlie);

        assertTrue(balanceAlice / 2 == balanceBob);
        assertTrue(balanceAlice / 4 == balanceCharlie);
        assertTrue(balanceBob == balanceCharlie * 2);
        assertTrue(balanceBob / 2 == balanceCharlie);

        assertTrue(ozERC20.totalSupply() == balanceAlice + balanceCharlie + balanceBob);
        assertTrue(ozERC20.totalAssets() / 10 ** IERC20Permit(testToken).decimals() == rawAmount + rawAmount / 2 + rawAmount / 4);
        assertTrue(ozERC20.totalShares() == sharesAlice + sharesBob + sharesCharlie);
    }   

    

    function test_transfer() public {
        //Pre-conditions
        uint rawAmount = 100;

        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, rawAmount * 10 ** IERC20Permit(testToken).decimals(), alice, ALICE_PK, true
        );

        uint balAlice = ozERC20.balanceOf(alice);
        assertTrue(balAlice > 99 * 1 ether && balAlice < rawAmount * 1 ether);

        uint balBob = ozERC20.balanceOf(bob);
        assertTrue(balBob == 0);

        //Action
        vm.prank(alice);
        ozERC20.transfer(bob, balAlice);

        //Post-conditions
        balAlice = ozERC20.balanceOf(alice);
        assertTrue(balAlice > 0 && balAlice < 0.000001 * 1 ether);

        balBob = ozERC20.balanceOf(bob);
        assertTrue(balBob > 99 * 1 ether && balBob < rawAmount * 1 ether);
    }


    function test_redeeming() public {
        //Pre-conditions
        uint amountIn = 100 * 10 ** IERC20Permit(testToken).decimals();

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true);
        testToken = address(ozERC20);

        //Action
        uint ozAmountIn = ozERC20.balanceOf(alice);
        

        (
            RequestType memory req,
            uint8 v, bytes32 r, bytes32 s
        ) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        // (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        // uint minUsdcOut = uint(price).mulDiv(req.exit.minAmountsOut[0], 1e8); //req.exit.minAmountsOut[0] --> minWethOutOffchain

        //Actions
        vm.prank(alice);
        ozERC20.burn(req.amtsOut, alice, v, r, s); 

        //Post-conditions
        uint minUsdcOut = req.amtsOut.minUsdcOut;
        assertTrue(minUsdcOut > 99 * 1 ether && minUsdcOut < 100 * 1 ether);


    }
     


    /** HELPERS ***/

    function _encode() private returns(bytes memory) {



    }
 

    function _createAndMintOzTokens(
        address testToken_,
        uint amountIn_, 
        address user_, 
        uint userPk_,
        bool create_
    ) private returns(ozIToken ozERC20, uint shares) {
        if (create_) {
            ozERC20 = ozIToken(OZ.createOzToken(
                testToken_, "Ozel-ERC20", "ozERC20"
            ));
        } else {
            ozERC20 = ozIToken(testToken_);
        }

        (
            RequestType memory req,
            uint8 v, bytes32 r, bytes32 s
        ) = _createDataOffchain(ozERC20, amountIn_, userPk_, user_, Type.IN);

        vm.prank(user_);
        shares = ozERC20.mint(req.amtsIn, user_, v, r, s); 
    }


    function _handleRequestOut(ozIToken ozERC20_, uint amountIn_) private returns(
        RequestType memory req,
        uint[] memory minAmountsOut,
        uint bptAmountIn
    ) {
        address[] memory assets = Helpers.convertToDynamic([wethAddr, rEthWethPoolBalancer, rEthAddr]);

        minAmountsOut = HelpersTests.calculateMinAmountsOut(
            rEthWethPoolBalancer, ozERC20_, amountIn_, defaultSlippage
        );

        uint shares = ozERC20_.previewWithdraw(amountIn_);
        bptAmountIn = ozERC20_.convertToUnderlying(shares);

        IVault.ExitPoolRequest memory request = Helpers.createExitRequest(
            assets, minAmountsOut, Helpers.createUserData(IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, 0)
        );

        req.exit = request;
        req.req = Type.OUT;
    }




    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint amountIn_,
        uint SENDER_PK_,
        address sender_,
        Type reqType
    ) private returns( 
        RequestType memory req,
        uint8 v, bytes32 r, bytes32 s
    ) {
        uint[] memory minAmountsOut;
        uint bptAmountIn;
        address[] memory assets;

        if (reqType == Type.OUT) {
            // ReqOut memory reqOut = ReqOut(
            //     address(ozERC20_),
            //     wethAddr,
            //     rEthWethPoolBalancer,
            //     rEthAddr,
            //     amountIn_,
            //     defaultSlippage
            // );

            // bytes memory data = abi.encode(reqOut);

            bytes memory data = _getBytesReqOut(address(ozERC20_), amountIn_);

            (
                RequestType memory req,
                uint[] memory minAmountsOutInternal,
                uint bptAmountIn
            ) = HelpersTests.handleRequestOut(data);

            minAmountsOut = minAmountsOutInternal;
        } else if (reqType == Type.IN) { 
            // ReqIn memory reqIn = ReqIn(
            //     address(ozERC20_),
            //     ethUsdChainlink,
            //     rEthEthChainlink,
            //     testToken,
            //     wethAddr,
            //     rEthWethPoolBalancer,
            //     rEthAddr,
            //     defaultSlippage,
            //     amountIn_
            // );

            // bytes memory data = abi.encode(reqIn);

            bytes memory data = _getBytesReqIn(address(ozERC20_), amountIn_);

            (
                RequestType memory req,
                uint[] memory minAmountsOutInternal
            ) = HelpersTests.handleRequestIn(data);

            minAmountsOut = minAmountsOutInternal;
        }
        
        (uint amountOut, bytes32 permitHash) = _getHashNAmountOut(sender_, req, amountIn_);

        (v, r, s) = vm.sign(SENDER_PK_, permitHash);

        if (reqType == Type.OUT) { 
            uint minWethOut = Helpers.calculateMinAmountOut(amountOut, defaultSlippage);

            (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
            uint minUsdcOut = uint(price).mulDiv(minWethOut, 1e8);

            req.amtsOut = TradeAmountsOut({
                ozAmountIn: amountIn_,
                minWethOut: minWethOut,
                bptAmountIn: bptAmountIn,
                minUsdcOut: minUsdcOut
            });
        } else if (reqType == Type.IN) {
            req.amtsIn = TradeAmounts({
                amountIn: amountIn_,
                minWethOut: minAmountsOut[0],
                minRethOut: minAmountsOut[1],
                minBptOut: HelpersTests.calculateMinAmountsOut(amountOut, defaultSlippage)
            });
        }
    }
    


    function _getHashNAmountOut(
        address sender_,
        RequestType memory request_, 
        uint amountIn_
    ) internal returns(uint, bytes32) {
        uint bptOut;
        uint[] memory amountsOut;
        uint paramOut;

        if (request_.req == Type.IN) {
            (bptOut,) = IQueries(queriesBalancer).queryJoin(
                IPool(rEthWethPoolBalancer).getPoolId(),
                sender_,
                address(ozDiamond),
                request_.join
            );

            paramOut = bptOut;
        } else if (request_.req == Type.OUT) {
            (,amountsOut) = IQueries(queriesBalancer).queryExit(
                IPool(rEthWethPoolBalancer).getPoolId(),
                alice,
                address(ozDiamond),
                request_.exit
            );

            paramOut = amountsOut[0];
        }

        bytes32 permitHash = HelpersTests.getPermitHash(
            testToken,
            sender_,
            address(ozDiamond),
            amountIn_,
            IERC20Permit(testToken).nonces(sender_),
            block.timestamp
        );

        return (paramOut, permitHash);
    }
}