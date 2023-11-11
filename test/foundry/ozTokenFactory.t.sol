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
import "solady/src/utils/FixedPointMathLib.sol";
import {Type, RequestType, ReqIn, ReqOut} from "./AppStorageTests.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;
    // using stdStorage for StdStorage;



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

    /**
     * From 1M USDC balance, mint 1M and redeem 1M
     */
    function test_redeeming_bigBalance_bigMint_bigRedeem() public {
        //Pre-conditions
        uint newSlippage = 9900;
        vm.prank(owner);
        OZ.changeDefaultSlippage(newSlippage);
        assertTrue(OZ.getDefaultSlippage() == newSlippage);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceOzUsdcAlice = ozERC20.balanceOf(alice);
        assertTrue(balanceOzUsdcAlice > 990_000 * 1 ether && balanceOzUsdcAlice < 1_000_000 * 1 ether);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
        ozERC20.burn(req.amtsOut, alice); 

        //Post-conditions
        testToken = usdcAddr;
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);
       
        assertTrue(balanceUnderlyingAlice > 998_000 * decimalsUnderlying && balanceUnderlyingAlice < 1_000_000 * decimalsUnderlying);
        assertTrue(ozERC20.balanceOf(alice) == 0);
    }


    /**
     * From 1M USDC balance, mint and redeem a small part (100 USDC)
     */
    function test_redeeming_bigBalance_smallMint_smallRedeem() public {
        //Pre-conditions
        uint newSlippage = 9900;
        vm.prank(owner);
        OZ.changeDefaultSlippage(newSlippage);
        assertTrue(OZ.getDefaultSlippage() == newSlippage);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = 100 * decimalsUnderlying;
        assertTrue(IERC20Permit(usdcAddr).balanceOf(alice) == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        assertTrue(ozAmountIn > 99 * 1 ether && ozAmountIn < 100 * 1 ether);
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);

        uint underlyingOut = ozERC20.burn(req.amtsOut, alice); 

        //Post-conditions
        testToken = usdcAddr;
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(ozERC20.balanceOf(alice) == 0);
        assertTrue(underlyingOut > 99 * decimalsUnderlying && underlyingOut < 100 * decimalsUnderlying);

        uint finalUnderlyingNetBalanceAlice = balanceUsdcAlicePostMint + underlyingOut;
        assertTrue(finalUnderlyingNetBalanceAlice > 999_000 * decimalsUnderlying && finalUnderlyingNetBalanceAlice < 1_000_000 * decimalsUnderlying);
    }

    function _getETHprices() private view returns(uint) {
        // console.log('--- new round of prices ---');
        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        // console.log('ETHUSD price chainlink: ', uint(price));

        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(wethUsdPoolUni).slot0();
        console.log('sqrtPriceX96: ', uint(sqrtPriceX96));

        uint priceSpotUni = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);
        console.log('spot price uni ****: ', priceSpotUni);
        // console.log(' --- end of new round ---');

        return uint(sqrtPriceX96);
    }

    function _getSqrtPriceX96Diff(uint high_, uint low_) private pure returns(uint) {
        return (high_ - low_).mulDiv(10000, high_);
    }


    function _changeSlippage(uint basisPoints_) private {
        vm.prank(owner);
        OZ.changeDefaultSlippage(basisPoints_);
        assertTrue(OZ.getDefaultSlippage() == basisPoints_);
    }


    function test_redeeming_balancingPool() public {
        uint sqrtPriceX96_1 = _getETHprices();
        //Pre-conditions
        _changeSlippage(9900);

        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * 1e6);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);

        uint sqrtPriceX96_2 = _getETHprices();

        uint sqrtDiff = _getSqrtPriceX96Diff(sqrtPriceX96_2, sqrtPriceX96_1);
        console.log('diff: ', sqrtDiff);

        //----------------
        // amountIn = IERC20Permit(testToken).balanceOf(bob);
        // _createAndMintOzTokens(address(ozERC20), amountIn, bob, BOB_PK, false, false);
        // uint balanceUsdcBobPostMint = IERC20Permit(testToken).balanceOf(bob);
        // assertTrue(balanceUsdcBobPostMint == 0);
        // uint balanceOzBobPostMint = ozERC20.balanceOf(bob);
        // console.log('balanceOzBobPostMint: ', balanceOzBobPostMint);

        // _getETHprices();


    }


    /** REFERENCE
     * Used quantities like 100 USDC to mint ozUSDC, where redeeming 1 ozUSDC, would
     * be ineligble so the MEV produce is quite lower, proving the efficacy of algo
     */
    function test_redeeming_multipleBigBalances_smallRedeemQuantities() public {
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 100 * 1e6);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);

        //----------
        amountIn = IERC20Permit(testToken).balanceOf(bob);
        _createAndMintOzTokens(address(ozERC20), amountIn, bob, BOB_PK, false, false);
        uint balanceUsdcBobPostMint = IERC20Permit(testToken).balanceOf(bob);
        assertTrue(balanceUsdcBobPostMint == 0);
        uint balanceOzBobPostMint = ozERC20.balanceOf(bob);
        assertTrue(balanceOzBobPostMint > 199 * 1 ether && balanceOzBobPostMint < 200 * 1 ether);

        amountIn = IERC20Permit(testToken).balanceOf(charlie);
        _createAndMintOzTokens(address(ozERC20), amountIn, charlie, CHARLIE_PK, false, false);
        uint balanceUsdcCharliePostMint = IERC20Permit(testToken).balanceOf(charlie);
        assertTrue(balanceUsdcCharliePostMint == 0);
        uint balanceOzCharliePostMint = ozERC20.balanceOf(charlie);
        assertTrue(balanceOzCharliePostMint > 299 * 1 ether && balanceOzCharliePostMint < 300 * 1 ether);
        //----------

        uint ozAmountIn = 1 * 1 ether;
        testToken = address(ozERC20);
        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
        uint underlyingOut = ozERC20.burn(req.amtsOut, alice);

        //Post-conditions
        uint balanceOzBobPostBurn = ozERC20.balanceOf(bob);
        uint balanceOzCharliePostBurn = ozERC20.balanceOf(charlie);
        uint basisPointsDifferenceBobMEV = (balanceOzBobPostMint - balanceOzBobPostBurn).mulDiv(10000, balanceOzBobPostMint);
        uint basisPointsDifferenceCharlieMEV = (balanceOzCharliePostMint - balanceOzCharliePostBurn).mulDiv(10000, balanceOzCharliePostMint);

        assertTrue(underlyingOut == IERC20Permit(usdcAddr).balanceOf(alice));
        assertTrue(basisPointsDifferenceBobMEV == 0);
        assertTrue(basisPointsDifferenceCharlieMEV == 0);
    }


    //Problem here ****
    function test_redeeming_multipleBigBalances_bigMint_mediumRedeem() public {
        //Pre-conditions
        uint newSlippage = 9900;
        vm.prank(owner);
        OZ.changeDefaultSlippage(newSlippage);
        assertTrue(OZ.getDefaultSlippage() == newSlippage);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);
        console.log('--- pre-condition ---');
        console.log('bal alice oz post-mint: ', ozERC20.balanceOf(alice));

        //-------------------
        amountIn = IERC20Permit(testToken).balanceOf(bob);
        _createAndMintOzTokens(address(ozERC20), amountIn, bob, BOB_PK, false, false);
        uint balanceUsdcBobPostMint = IERC20Permit(testToken).balanceOf(bob);
        assertTrue(balanceUsdcBobPostMint == 0);
        console.log('bal bob oz post-mint: ', ozERC20.balanceOf(bob));

        amountIn = IERC20Permit(testToken).balanceOf(charlie);
        _createAndMintOzTokens(address(ozERC20), amountIn, charlie, CHARLIE_PK, false, false);
        uint balanceUsdcCharliePostMint = IERC20Permit(testToken).balanceOf(charlie);
        assertTrue(balanceUsdcCharliePostMint == 0);
        console.log('bal charlie oz post-mint: ', ozERC20.balanceOf(charlie));
        //-------------------

        uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
        uint underlyingOut = ozERC20.burn(req.amtsOut, alice);

        //Post-conditions
        console.log('--- post-conditon ---');
        console.log('ozAmountIn alice to redeem: ', ozAmountIn);
        console.log('usdc out: ', underlyingOut);
        console.log('bal alice usdc post-burn: ', IERC20Permit(usdcAddr).balanceOf(alice));

    }


    //Problem here (same as below) ******
    function test_redeeming_bigBalance_bigMint_mediumRedeem() public {
        //Pre-conditions
        uint newSlippage = 9900;
        vm.prank(owner);
        OZ.changeDefaultSlippage(newSlippage);
        assertTrue(OZ.getDefaultSlippage() == newSlippage);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);

        uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
        console.log('ozAmountIn: ', ozAmountIn);
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);

        uint underlyingOut = ozERC20.burn(req.amtsOut, alice);
        console.log('underlyingOut: ', underlyingOut);
    }


    //Problem here ***
    function test_redeeming_bigBalance_bigMint_smallRedeem() public {
        //Pre-conditions
        uint newSlippage = 9900;
        vm.prank(owner);
        OZ.changeDefaultSlippage(newSlippage);
        assertTrue(OZ.getDefaultSlippage() == newSlippage);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);

        uint ozAmountIn = 100 * 1 ether;
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);

        uint underlyingOut = ozERC20.burn(req.amtsOut, alice);
        console.log('underlyingOut: ', underlyingOut);
    }


    function test_redeeming_approve() public {
        //Pre-conditions
        uint newSlippage = 9900;
        vm.prank(owner);
        OZ.changeDefaultSlippage(newSlippage);
        assertTrue(OZ.getDefaultSlippage() == newSlippage);

        uint amountIn = IERC20Permit(testToken).balanceOf(alice) / 10;
        console.log('amountIn from usdc to create ozUSDC (/10): ', amountIn);
        // uint amountIn = 100 * 1e6;
        assertTrue(amountIn > 0);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);

        //-------------
        // uint rawAmount = 1_000_000;
        // amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        // _createAndMintOzTokens(
        //     address(ozERC20), amountIn, bob, BOB_PK, false, true
        // );

        // amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        // _createAndMintOzTokens(
        //     address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true
        // );
        //-------------


        uint ozAmountIn = ozERC20.balanceOf(alice);
        uint balanceOzBobPre = ozERC20.balanceOf(bob);
        uint balanceOzCharliePre = ozERC20.balanceOf(charlie);
        testToken = address(ozERC20);

        (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);

        console.log('bal usdc alice pre: ', IERC20Permit(usdcAddr).balanceOf(alice));
        console.log('bal oz alice pre: ', ozERC20.balanceOf(alice));

        ozERC20.burn(req.amtsOut, alice); 

        console.log('bal usdc alice post: ', IERC20Permit(usdcAddr).balanceOf(alice));
        console.log('bal oz alice post: ', ozERC20.balanceOf(alice));

        //Post-conditions
        testToken = usdcAddr;
        // uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        // uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);
        // uint balanceOzBobPost = ozERC20.balanceOf(bob);
        // uint balanceOzCharliePost = ozERC20.balanceOf(charlie);

        // assertTrue(balanceUnderlyingAlice > 99 * decimalsUnderlying && balanceUnderlyingAlice < 100 * decimalsUnderlying);
       
        // console.log('balanceOzBobPre: ', balanceOzBobPre);
        // console.log('balanceOzBobPost: ', balanceOzBobPost);
        // console.log('balanceOzCharliePre: ', balanceOzCharliePre);
        // console.log('balanceOzCharliePost: ', balanceOzCharliePost);

        // assertTrue(balanceOzBobPre == balanceOzBobPost && balanceOzCharliePre == balanceOzCharliePost);
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
            uint minWethOut = Helpers.calculateMinAmountOut(amountOut_, OZ.getDefaultSlippage());

            (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
            uint minUsdcOut = uint(price).mulDiv(minWethOut, 1e8);

            req.amtsOut = AmountsOut({
                ozAmountIn: amountIn_,
                minWethOut: minWethOut,
                bptAmountIn: bptAmountIn_,
                minUsdcOut: minUsdcOut
            });
        } else if (reqType_ == Type.IN) {
            req.amtsIn = AmountsIn({
                amountIn: amountIn_,
                minWethOut: minAmountsOut_[0],
                minRethOut: minAmountsOut_[1],
                minBptOut: HelpersTests.calculateMinAmountsOut(amountOut_, OZ.getDefaultSlippage())
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
        OZ.getDefaultSlippage()
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
            OZ.getDefaultSlippage(),
            amountIn_
        );

        return abi.encode(reqIn);
    }
}