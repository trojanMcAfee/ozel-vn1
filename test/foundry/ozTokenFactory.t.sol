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
import {TradeAmounts, TradeAmountsOut} from "../../contracts/AppStorage.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersTests} from "./HelpersTests.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import {Type, RequestType, ReqIn, ReqOut} from "./AppStorageTests.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;


    function test_minting_approve() public {
        //Pre-condition
        uint rawAmount = 100;
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }


    function test_minting_eip2612() public {
        /**
         * Pre-conditions + Actions (creating of ozTokens)
         */
        uint rawAmount = 100;
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true
        );

        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesBob) = _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true
        );

        amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true
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
            testToken, rawAmount * 10 ** IERC20Permit(testToken).decimals(), alice, ALICE_PK, true, true
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


    function test_redeeming_approve() public {
        //Pre-conditions
        uint amountIn = IERC20Permit(testToken).balanceOf(alice); 
        assertTrue(amountIn > 0);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
        ozERC20.burn(req.amtsOut, alice); 

        //Post-conditions
        testToken = usdcAddr;
        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);

        assertTrue(balanceUnderlyingAlice > 99 * decimalsUnderlying && balanceUnderlyingAlice < 100 * decimalsUnderlying);
        assertTrue(ozERC20.totalSupply() == 0);
        assertTrue((ozERC20.totalAssets() / decimalsUnderlying) == 0);
        assertTrue((ozERC20.totalShares() / decimalsUnderlying) == 0);
        assertTrue((ozERC20.sharesOf(alice) / decimalsUnderlying) == 0);
        assertTrue((ozERC20.balanceOf(alice) / ozERC20.decimals()) == 0);
    }


    function test_redeeming_eip2612() public {
        //Pre-conditions
        uint amountIn = IERC20Permit(testToken).balanceOf(alice); 
        assertTrue(amountIn > 0);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);
        
        (
            RequestType memory req,
            uint8 v, bytes32 r, bytes32 s
        ) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);


        //Action
        vm.startPrank(alice);
        ozERC20.permit(
            alice,
            address(ozDiamond),
            req.amtsOut.ozAmountIn,
            block.timestamp,
            v, r, s
        );

        ozERC20.burn(req.amtsOut, alice); 

        //Post-conditions
        testToken = usdcAddr;
        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);

        assertTrue(balanceUnderlyingAlice > 99 * decimalsUnderlying && balanceUnderlyingAlice < 100 * decimalsUnderlying);
        assertTrue(ozERC20.totalSupply() == 0);
        assertTrue((ozERC20.totalAssets() / decimalsUnderlying) == 0);
        assertTrue((ozERC20.totalShares() / decimalsUnderlying) == 0);
        assertTrue((ozERC20.sharesOf(alice) / decimalsUnderlying) == 0);
        assertTrue((ozERC20.balanceOf(alice) / ozERC20.decimals()) == 0);
    }
     

    /** HELPERS ***/
   function _createRequestType(
        Type reqType_,
        uint amountOut_,
        uint amountIn_,
        uint bptAmountIn_,
        uint[] memory minAmountsOut_
    ) private view returns(RequestType memory req) {
        if (reqType_ == Type.OUT) { 
            uint minWethOut = Helpers.calculateMinAmountOut(amountOut_, defaultSlippage);

            (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
            uint minUsdcOut = uint(price).mulDiv(minWethOut, 1e8);

            req.amtsOut = TradeAmountsOut({
                ozAmountIn: amountIn_,
                minWethOut: minWethOut,
                bptAmountIn: bptAmountIn_,
                minUsdcOut: minUsdcOut
            });
        } else if (reqType_ == Type.IN) {
            req.amtsIn = TradeAmounts({
                amountIn: amountIn_,
                minWethOut: minAmountsOut_[0],
                minRethOut: minAmountsOut_[1],
                minBptOut: HelpersTests.calculateMinAmountsOut(amountOut_, defaultSlippage)
            });
        }
   }
 

    function _createAndMintOzTokens(
        address testToken_,
        uint amountIn_, 
        address user_, 
        uint userPk_,
        bool create_,
        bool is2612_
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

        vm.startPrank(user_);

        if (is2612_) {
            IERC20Permit(testToken).permit(
                user_, 
                address(ozDiamond), 
                req.amtsIn.amountIn, 
                block.timestamp, 
                v, r, s
            );
        } else {
            IERC20Permit(testToken).approve(address(ozDiamond), req.amtsIn.amountIn);
        }

        shares = ozERC20.mint(req.amtsIn, user_); 
        vm.stopPrank();
    }


    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint amountIn_,
        uint SENDER_PK_,
        address sender_,
        Type reqType_
    ) private returns( 
        RequestType memory req,
        uint8 v, bytes32 r, bytes32 s
    ) {
        uint[] memory minAmountsOut;
        uint bptAmountIn;

        if (reqType_ == Type.OUT) {
            bytes memory data = _getBytesReqOut(address(ozERC20_), amountIn_);

            (
                RequestType memory reqInternal,
                uint[] memory minAmountsOutInternal,
                uint bptAmountInternal
            ) = HelpersTests.handleRequestOut(data);

            minAmountsOut = minAmountsOutInternal;
            req = reqInternal;
            bptAmountIn = bptAmountInternal;
        } else if (reqType_ == Type.IN) { 
            bytes memory data = _getBytesReqIn(address(ozERC20_), amountIn_);

            (
                RequestType memory reqInternal,
                uint[] memory minAmountsOutInternal
            ) = HelpersTests.handleRequestIn(data);

            minAmountsOut = minAmountsOutInternal;
            req = reqInternal;
        }

        (uint amountOut, bytes32 permitHash) = _getHashNAmountOut(sender_, req, amountIn_);

        (v, r, s) = vm.sign(SENDER_PK_, permitHash);

        req = _createRequestType(reqType_, amountOut, amountIn_, bptAmountIn, minAmountsOut);
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


    function _getBytesReqOut(address ozERC20Addr_, uint amountIn_) private view returns(bytes memory) {
        ReqOut memory reqOut = ReqOut(
        ozERC20Addr_,
        wethAddr,
        rEthWethPoolBalancer,
        rEthAddr,
        amountIn_,
        defaultSlippage
    );

        return abi.encode(reqOut);
    }

    function _getBytesReqIn(address ozERC20Addr_, uint amountIn_) private view returns(bytes memory) {
        ReqIn memory reqIn = ReqIn(
            ozERC20Addr_,
            ethUsdChainlink,
            rEthEthChainlink,
            testToken,
            wethAddr,
            rEthWethPoolBalancer,
            rEthAddr,
            defaultSlippage,
            amountIn_
        );

        return abi.encode(reqIn);
    }
}