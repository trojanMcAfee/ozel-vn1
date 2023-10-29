// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
// import "solady/src/utils/FixedPointMathLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IQueries, IPool, IAsset, IVault} from "../../contracts/interfaces/IBalancer.sol";
import {Helpers} from "../../contracts/libraries/Helpers.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {TradeAmounts, TradeAmountsOut} from "../../contracts/AppStorage.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersTests} from "./HelpersTests.sol";
import "solady/src/utils/FixedPointMathLib.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;


    function test_minting() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        //Actions
        uint rawAmount = 100;
        uint sharesAlice = _mintOzTokens(ozERC20, rawAmount, alice, ALICE_PK);
        uint sharesBob = _mintOzTokens(ozERC20, rawAmount / 2, bob, BOB_PK);
        uint sharesCharlie = _mintOzTokens(ozERC20, rawAmount / 4, charlie, CHARLIE_PK);

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

    
    function test_totalUnderlying() public {
        //Pre-conditions
        uint rawAmount = 100;

        ozIToken ozERC20 = _createAndMintOzTokens(testToken, rawAmount, alice, ALICE_PK);

        uint balAlice = ozERC20.balanceOf(alice);
        assertTrue(balAlice > 99 * 1 ether && balAlice < rawAmount * 1 ether);

        uint balBob = ozERC20.balanceOf(bob);
        assertTrue(balBob == 0);

        //Action
        vm.startPrank(alice);
        // ozERC20.transfer(bob, balAlice);
        // ozERC20.approve(address(ozERC20), type(uint).max);
        ozERC20.burn2(balAlice, bob);

        uint bal = ozERC20.balanceOf(alice);
        console.log('bal - should 0: ', bal);

        bal = ozERC20.balanceOf(bob);
        console.log('should not 0: ', bal);
    }


    function test_transfer() public {
        //Pre-conditions
        uint rawAmount = 100;

        ozIToken ozERC20 = _createAndMintOzTokens(testToken, rawAmount, alice, ALICE_PK);

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

        ozIToken ozERC20 = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK);
        testToken = address(ozERC20);

        //Action
        uint ozAmountIn = ozERC20.balanceOf(alice);

        (
            // uint minUsdcOut,
            // TradeAmountsOut memory amts,
            RequestType memory req,
            uint8 v, bytes32 r, bytes32 s
        ) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);
   
        // address[] memory assets = Helpers.convertToDynamic([wethAddr, rEthWethPoolBalancer, rEthAddr]);


        // uint[] memory minAmountsOut = HelpersTests.calculateMinAmountsOut(
        //     rEthWethPoolBalancer, ozERC20, ozAmountIn, defaultSlippage
        // );

        //------
        // uint shares = ozERC20.previewWithdraw(ozAmountIn);
        // uint bptAmountIn = ozERC20.convertToUnderlying(shares);
        //-------


        // IVault.ExitPoolRequest memory request = Helpers.createExitRequest(
        //     assets, minAmountsOut, Helpers.createUserData(IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, 0)
        // );


        // (uint amountWethOut2, bytes32 permitHash) = _getHashNBptOut2(alice, request, ozAmountIn);

        // uint minWethAmountOffchain = Helpers.calculateMinAmountOut(amountWethOut2, defaultSlippage);

        // (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();

        // uint minUsdcOut = uint(price).mulDiv(minWethAmountOffchain, 1e8);
        // *****
        // (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        // minUsdcOut = uint(price).mulDiv(minWethAmountOffchain, 1e8);
        // assertTrue(minUsdcOut > 99 * 1 ether && minUsdcOut < 100 * 1 ether);
        
        //--------------------------------------

        // TradeAmountsOut memory amts = TradeAmountsOut({
        //     ozAmountIn: ozAmountIn,
        //     minWethOut: minWethAmountOffchain,
        //     bptAmountIn: bptAmountIn
        // });


        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, permitHash);

        vm.prank(alice);
        ozERC20.burn(req.amtsOut, alice, v, r, s); 


    }
     








    /** HELPERS ***/

    function _createAndMintOzTokens(
        address testToken_,
        uint amountIn_, 
        address user_, 
        uint userPk_
    ) private returns(ozIToken) {
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken_, "Ozel-ERC20", "ozERC20"
        ));

        // (
        //     TradeAmounts memory amounts,
        //     uint8 v, bytes32 r, bytes32 s
        // ) = _createDataOffchain(ozERC20, amountIn_, userPk_, user_);

        (
            // uint minUsdcOut,
            // TradeAmountsOut memory amts,
            RequestType memory req,
            uint8 v, bytes32 r, bytes32 s
        ) = _createDataOffchain(ozERC20, amountIn_, ALICE_PK, alice, Type.IN);

        vm.prank(user_);
        ozERC20.mint(req.amtsIn, user_, v, r, s); 

        return ozERC20;
    }

    function _mintOzTokens(
        ozIToken ozERC20_,
        uint rawAmount_, 
        address user_, 
        uint userPk_
    ) private returns(uint) {
        // (
        //     TradeAmounts memory amounts,
        //     uint8 v, bytes32 r, bytes32 s
        // ) = _createDataOffchain(ozERC20_, rawAmount_, userPk_, user_, Type.IN);

        // vm.prank(user_);
        // uint shares = ozERC20_.mint(amounts, user_, v, r, s); 

        // return shares;
    }


    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint amountIn_,
        uint SENDER_PK_,
        address sender_,
        Type reqType
    ) private returns(
        // uint minUsdcOut, 
        // TradeAmountsOut memory amts,
        RequestType memory req,
        uint8 v, bytes32 r, bytes32 s
    ) {
        uint[] memory minAmountsOut;
        uint bptAmountIn;
        address[] memory assets;

        if (reqType == Type.OUT) {
            assets = Helpers.convertToDynamic([wethAddr, rEthWethPoolBalancer, rEthAddr]);

            minAmountsOut = HelpersTests.calculateMinAmountsOut(
                rEthWethPoolBalancer, ozERC20_, amountIn_, defaultSlippage
            );

            uint shares = ozERC20_.previewWithdraw(amountIn_);
            bptAmountIn = ozERC20_.convertToUnderlying(shares);

            IVault.ExitPoolRequest memory request = Helpers.createExitRequest(
                assets, minAmountsOut, Helpers.createUserData(IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, 0)
            );

            // RequestType memory req;
            req.exit = request;
            req.req = Type.OUT;
        } else if (reqType == Type.IN) {
            minAmountsOut = HelpersTests.calculateMinAmountsOut(
                [ethUsdChainlink, rEthEthChainlink], amountIn_ / 10 ** IERC20Permit(testToken).decimals(), ozERC20_.decimals(), defaultSlippage
            );

            (
                address[] memory assets2,
                uint[] memory maxAmountsIn,
                uint[] memory amountsIn
            ) = Helpers.convertToDynamics([wethAddr, rEthWethPoolBalancer, rEthAddr], minAmountsOut[1]);

            IVault.JoinPoolRequest memory request = Helpers.createRequest(
                assets2, maxAmountsIn, Helpers.createUserData(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0)
            );

            // RequestType memory req;
            req.join = request;
            req.req = Type.IN;
        }
        
        // (uint amountWethOut, bytes32 permitHash) = _getHashNBptOut(sender_, req, ozAmountIn_);
        (uint amountOut, bytes32 permitHash) = _getHashNBptOut(sender_, req, amountIn_);

        (v, r, s) = vm.sign(SENDER_PK_, permitHash);

        //-------
        // (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        // minUsdcOut = uint(price).mulDiv(minWethAmountOffchain, 1e8);
        //-------

        if (reqType == Type.OUT) {
            req.amtsOut = TradeAmountsOut({
                ozAmountIn: amountIn_,
                minWethOut: Helpers.calculateMinAmountOut(amountOut, defaultSlippage),
                bptAmountIn: bptAmountIn
            });

            // req.amtsOut = amounts;
        } else if (reqType == Type.IN) {
            req.amtsIn = TradeAmounts({
                amountIn: amountIn_,
                minWethOut: minAmountsOut[0],
                minRethOut: minAmountsOut[1],
                minBptOut: HelpersTests.calculateMinAmountsOut(amountOut, defaultSlippage)
            });

            // req.amtsIn = amounts;
        }

        // (v, r, s) = vm.sign(SENDER_PK_, permitHash);
    }
    


    // function _createDataOffchain( 
    //     ozIToken ozERC20_, 
    //     uint amountIn_,
    //     uint SENDER_PK_,
    //     address sender_
    // ) private returns(TradeAmounts memory amounts, uint8 v, bytes32 r, bytes32 s) { 
    //     // uint amountIn = rawAmount_ * 10 ** IERC20Permit(testToken).decimals();

    //     uint[] memory minsOut = HelpersTests.calculateMinAmountsOut(
    //         [ethUsdChainlink, rEthEthChainlink], amountIn_ / 10 ** IERC20Permit(testToken).decimals(), ozERC20_.decimals(), defaultSlippage
    //     );

    //     (
    //         address[] memory assets,
    //         uint[] memory maxAmountsIn,
    //         uint[] memory amountsIn
    //     ) = Helpers.convertToDynamics([wethAddr, rEthWethPoolBalancer, rEthAddr], minsOut[1]);

    //     IVault.JoinPoolRequest memory request = Helpers.createRequest(
    //         assets, maxAmountsIn, Helpers.createUserData(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0)
    //     );

    //     RequestType memory req;
    //     req.join = request;
    //     req.req = Type.IN;

    //     (uint bptOut, bytes32 permitHash) = _getHashNBptOut(sender_, req, amountIn_);

    //     (v, r, s) = vm.sign(SENDER_PK_, permitHash);

    //     amounts = TradeAmounts({
    //         amountIn: amountIn,
    //         minWethOut: minsOut[0],
    //         minRethOut: minsOut[1],
    //         minBptOut: HelpersTests.calculateMinAmountsOut(bptOut, defaultSlippage)
    //     });
    // }

    enum Type {
        IN,
        OUT
    }

    struct RequestType {
        IVault.JoinPoolRequest join;
        IVault.ExitPoolRequest exit;
        Type req;
        TradeAmounts amtsIn;
        TradeAmountsOut amtsOut;
    }


    function _getHashNBptOut(
        address sender_,
        RequestType memory request_, //IVault.JoinPoolRequest memory request_
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

    // function _getHashNBptOut2(
    //     address sender_,
    //     RequestType memory request_, //IVault.ExitPoolRequest memory request_
    //     uint ozAmountIn_
    // ) internal returns(uint, bytes32) {
    //     (, uint[] memory amountsOut) = IQueries(queriesBalancer).queryExit(
    //         IPool(rEthWethPoolBalancer).getPoolId(),
    //         alice,
    //         address(ozDiamond),
    //         request_
    //     );

    //     bytes32 permitHash = HelpersTests.getPermitHash(
    //         testToken,
    //         sender_,
    //         address(ozDiamond),
    //         ozAmountIn_,
    //         IERC20Permit(testToken).nonces(sender_),
    //         block.timestamp
    //     );

    //     return (amountsOut[0], permitHash);
    // }
    


    




}