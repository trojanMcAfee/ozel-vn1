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
import {TradeAmounts, TradeAmountsOut} from "../../contracts/AppStorage.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersTests} from "./HelpersTests.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {


    function test_minting() internal {
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


    function test_redeeming() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        uint rawAmount = 100;
        uint sharesAlice = _mintOzTokens(ozERC20, rawAmount, alice, ALICE_PK);

        //Action
        uint ozAmountIn = ozERC20.balanceOf(alice);
        // uint minWethOut = 

        // address[] memory assets = new address[](3);
        // assets[0] = wethAddr;
        // assets[1] = rEthWethPoolBalancer;
        // assets[2] = rEthAddr;
        address[] memory assets = Helpers.convertToDynamic([s.WETH, s.rEthWethPoolBalancer, s.rETH]);

        // uint[] memory minAmountsOut = new uint[](2);
        // minAmountsOut[0] = Helpers.calculateMinAmountOut(bptAmountIn);
        // minAmountsOut[1] = 0;
         uint[] memory minAmountsOut = HelpersTests.calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], ozAmountIn / 1 ether, ozERC20_.decimals(), defaultSlippage
        );

        uint exitTokenIndex = 0;
        bytes memory userData = Helpers.createUserData(
            IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, exitTokenIndex
        );


        // (
        //     address[] memory assets,
        //     uint[] memory maxAmountsIn,
        //     uint[] memory amountsIn
        // ) = Helpers.convertToDynamics([wethAddr, rEthWethPoolBalancer, rEthAddr], minsOut[1]);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: userData,
            toInternalBalance: false 
        });

        (, uint[] memory amountsOut) = IQueries(s.queriesBalancer).queryExit(
            IPool(rEthWethPoolBalancer).getPoolId(),
            alice,
            address(ozDiamond),
            request
        );

        TradeAmountsOut memory amts = TradeAmountsOut({
            ozAmountIn: ozAmountIn,
            minWethOut: amountsOut[0],
            bptAmountIn: //how much BPT does my ozTokens get
        });

        vm.prank(alice);
        ozERC20.burn(minWethOut, bptAmountIn);

    }
     








    /** HELPERS ***/

    function _mintOzTokens(
        ozIToken ozERC20_,
        uint rawAmount_, 
        address user_, 
        uint userPk_
    ) private returns(uint) {
        (
            TradeAmounts memory amounts,
            uint8 v, bytes32 r, bytes32 s
        ) = _createDataOffchain(ozERC20_, rawAmount_, userPk_, user_);

        vm.prank(user_);
        uint shares = ozERC20_.mint(amounts, user_, v, r, s); 

        return shares;
    }


    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint rawAmount_,
        uint SENDER_PK_,
        address sender_
    ) private returns(TradeAmountsOut memory amts, uint8 v, bytes32 r, bytes32 s) {
        uint amountIn = rawAmount_ * 10 ** IERC20Permit(ozERC20_).decimals();

        uint[] memory minsOut = HelpersTests.calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], rawAmount_, ozERC20_.decimals(), defaultSlippage
        );
    }
    


    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint rawAmount_,
        uint SENDER_PK_,
        address sender_
    ) private returns(TradeAmounts memory amounts, uint8 v, bytes32 r, bytes32 s) { 
        uint amountIn = rawAmount_ * 10 ** IERC20Permit(testToken).decimals();

        uint[] memory minsOut = HelpersTests.calculateMinAmountsOut(
            [ethUsdChainlink, rEthEthChainlink], rawAmount_, ozERC20_.decimals(), defaultSlippage
        );

        (
            address[] memory assets,
            uint[] memory maxAmountsIn,
            uint[] memory amountsIn
        ) = Helpers.convertToDynamics([wethAddr, rEthWethPoolBalancer, rEthAddr], minsOut[1]);

        IVault.JoinPoolRequest memory request = Helpers.createRequest(
            assets, maxAmountsIn, Helpers.createUserData(IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0)
        );

        (uint bptOut, bytes32 permitHash) = _getHashNBptOut(sender_, request, amountIn);

        (v, r, s) = vm.sign(SENDER_PK_, permitHash);

        amounts = TradeAmounts({
            amountIn: amountIn,
            minWethOut: minsOut[0],
            minRethOut: minsOut[1],
            minBptOut: HelpersTests.calculateMinAmountsOut(bptOut, defaultSlippage)
        });

    }


    function _getHashNBptOut(
        address sender_,
        IVault.JoinPoolRequest memory request_,
        uint amountIn_
    ) internal returns(uint, bytes32) {
        (uint bptOut,) = IQueries(queriesBalancer).queryJoin(
            IPool(rEthWethPoolBalancer).getPoolId(),
            sender_,
            address(ozDiamond),
            request_
        );


        bytes32 permitHash = HelpersTests.getPermitHash(
            testToken,
            sender_,
            address(ozDiamond),
            amountIn_,
            IERC20Permit(testToken).nonces(sender_),
            block.timestamp
        );

        return (bptOut, permitHash);
    }
    


    




}