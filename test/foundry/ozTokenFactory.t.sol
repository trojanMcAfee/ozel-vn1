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
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {ozToken} from "../../contracts/ozToken.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

    using FixedPointMathLib for uint;
    using stdStorage for StdStorage;

    uint constant ONE_ETHER = 1 ether;


    /**
     * Mints a small quantity of ozUSDC (~100) through a Balancer swap
     */
    function test_minting_approve_smallMint_swapBalancer() public {
        //Pre-condition
        uint rawAmount = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }

    //--------
    function test_minting_approve_smallMint_rocketPool() public {
        //Pre-condition
        uint rawAmount = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _modifyRocketPoolDepositMaxLimit();

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }
    //---------


    /**
     * Mints a big quantity of ozUSDC (~1M)
     */
    function test_minting_approve_bigMint() public {
        //Pre-condition
        uint rawAmount = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(9900);

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
    }


    // enum User {
    //     ALICE,
    //     BOB,
    //     CHARLIE
    // }

    // function _compressMintData(uint rawAmount_) private view returns(
    //     bytes memory aliceData,
    //     bytes memory bobData,
    //     bytes memory charlieData
    // ) {
    //     uint amountIn = rawAmount_ * 10 ** IERC20Permit(testToken).decimals();

    //     aliceData = abi.encode(testToken, amountIn, alice, ALICE_PK, true, true);
    //     bobData = abi.encode(address(0), amountIn, bob, BOB_PK, false, true);
    //     charlieData = abi.encode(address(0), amountIn, charlie, CHARLIE_PK, false, true);
    // }

    

    // function test_computeAddress() public {
    //     bytes32 salt = bytes32(uint(123));
    //     address computedOzToken = address(new ozToken{salt: salt}());
    //     console.log('computedOzToken: ', computedOzToken);

    //     address oz = address(new ozToken());
    //     console.log('oz: ', oz);


    // }


    /**
     * Mints a small quantity of ozTokens using EIP2612
     */
    function test_minting_eip2612() public {
        /**
         * Pre-conditions + Actions (creating of ozTokens)
         */
        uint rawAmount = _dealUnderlying(Quantity.SMALL);
        // _compressMintData(rawAmount_);

        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );

        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesBob) = _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
        ); //try to join this 3 funcs in one

        amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
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

    
    /**
     * Transfer ozTokens between accounts
     */
    function test_transfer() public {
        //Pre-conditions
        uint rawAmount = _dealUnderlying(Quantity.SMALL);

        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, rawAmount * 10 ** IERC20Permit(testToken).decimals(), alice, ALICE_PK, true, true, Type.IN
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
    // function test_redeeming_bigBalance_bigMint_bigRedeem() public {
    //     //Pre-conditions
    //     _changeSlippage(9900);
    //     _dealUnderlying(Quantity.BIG);

    //     uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
    //     uint amountIn = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
    //     uint balanceOzUsdcAlice = ozERC20.balanceOf(alice);
    //     assertTrue(balanceOzUsdcAlice > 990_000 * 1 ether && balanceOzUsdcAlice < 1_000_000 * 1 ether);

    //     uint ozAmountIn = ozERC20.balanceOf(alice);
    //     testToken = address(ozERC20);

    //     (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

    //     //Action
    //     vm.startPrank(alice);
    //     ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
    //     ozERC20.burn(req.amtsOut, alice); 

    //     //Post-conditions
    //     testToken = usdcAddr;
    //     uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);
       
    //     assertTrue(balanceUnderlyingAlice > 998_000 * decimalsUnderlying && balanceUnderlyingAlice < 1_000_000 * decimalsUnderlying);
    //     assertTrue(ozERC20.balanceOf(alice) == 0);
    // }


    /**
     * From 1M USDC balance, mint and redeem a small part (100 USDC)
     */
    // function test_redeeming_bigBalance_smallMint_smallRedeem() public {
    //     //Pre-conditions
    //     _changeSlippage(9900);
    //     _dealUnderlying(Quantity.BIG);

    //     uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
    //     uint amountIn = 100 * decimalsUnderlying;
    //     assertTrue(IERC20Permit(usdcAddr).balanceOf(alice) == 1_000_000 * decimalsUnderlying);

    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
    //     uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);

    //     uint ozAmountIn = ozERC20.balanceOf(alice);
    //     assertTrue(ozAmountIn > 99 * 1 ether && ozAmountIn < 100 * 1 ether);
    //     testToken = address(ozERC20);

    //     (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

    //     //Action
    //     vm.startPrank(alice);
    //     ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
    //     uint underlyingOut = ozERC20.burn(req.amtsOut, alice); 

    //     //Post-conditions
    //     testToken = usdcAddr;
    //     uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(ozERC20.balanceOf(alice) == 0);
    //     assertTrue(underlyingOut > 99 * decimalsUnderlying && underlyingOut < 100 * decimalsUnderlying);

    //     uint finalUnderlyingNetBalanceAlice = balanceUsdcAlicePostMint + underlyingOut;
    //     assertTrue(finalUnderlyingNetBalanceAlice > 999_000 * decimalsUnderlying && finalUnderlyingNetBalanceAlice < 1_000_000 * decimalsUnderlying);
    // }

    

    /** REFERENCE
     * Mints 1M of ozTokens, then rebalances Uniswap and Balancer pools, 
     * and redeems a small portio of ozUSDC. 
     */
    // function test_redeeming_bigBalance_bigMint_smallRedeem() public {
    //     /**
    //      * Pre-conditions
    //      */
    //     //Deals big amounts of USDC to testers.
    //     _dealUnderlying(Quantity.BIG);
    //     uint amountIn = IERC20Permit(testToken).balanceOf(alice);
    //     uint rawAmount = 100;
    //     assertTrue(amountIn == 1_000_000 * 1e6);

    //     //Changes the default slippage to 99% so the swaps don't fail.
    //     _changeSlippage(9900);

    //     //Gets the pre-swap pool values.
    //     bytes32 oldSlot0data = vm.load(wethUsdPoolUni, bytes32(0));
    //     (,bytes32 wethBalanceBytes) = _getTokenBalanceFromSlot(wethAddr);

    //     //Creates an ozToken and mints some.
    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
    //     uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(balanceUsdcAlicePostMint == 0);

    //     //Returns balances to pre-swaps state so the rebase algorithm can be prorperly tested.
    //     _resetPoolBalances(oldSlot0data, wethAddr, wethBalanceBytes);

    //     uint ozAmountIn = rawAmount * 1 ether;
    //     testToken = address(ozERC20);

    //     //Creates offchain the token-amount variables needed for safe protocol execution.
    //     (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);
    
    //     /**
    //      * Action
    //      */
    //     vm.startPrank(alice);
    //     ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);

    //     //Redeems ozUSDC for USDC.
    //     uint underlyingOut = ozERC20.burn(req.amtsOut, alice);

    //     /**
    //      * Post-conditions
    //      */
    //     uint balanceAliceUnderlying = IERC20Permit(usdcAddr).balanceOf(alice);

    //     assertTrue(balanceAliceUnderlying < rawAmount * 1e6 && balanceAliceUnderlying > 99 * 1e6);
    //     assertTrue(balanceAliceUnderlying == underlyingOut);
    // }



    /**
     * Used quantities like 100 USDC to mint ozUSDC, where redeeming 1 ozUSDC, would
     * be ineligble so the MEV produced is quite lower, proving the efficacy of the 
     * rebase algorithm. 
     *
     * In this test, the "bigMint" is in relation to the amount being redeem (100:1)
     */
    // function test_redeeming_multipleBigBalances_bigMints_smallRedeem() public {
    //     _dealUnderlying(Quantity.SMALL);
    //     // uint amountToRedeem = 1;

    //     uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
    //     uint amountIn = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(amountIn == 100 * 1e6);

    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
    //     uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(balanceUsdcAlicePostMint == 0); 

    //     //----------
    //     amountIn = IERC20Permit(testToken).balanceOf(bob);
    //     _createAndMintOzTokens(address(ozERC20), amountIn, bob, BOB_PK, false, false);
    //     uint balanceUsdcBobPostMint = IERC20Permit(testToken).balanceOf(bob);
    //     assertTrue(balanceUsdcBobPostMint == 0);
    //     uint balanceOzBobPostMint = ozERC20.balanceOf(bob);
    //     assertTrue(balanceOzBobPostMint > 199 * 1 ether && balanceOzBobPostMint < 200 * 1 ether);

    //     amountIn = IERC20Permit(testToken).balanceOf(charlie);
    //     _createAndMintOzTokens(address(ozERC20), amountIn, charlie, CHARLIE_PK, false, false);
    //     uint balanceUsdcCharliePostMint = IERC20Permit(testToken).balanceOf(charlie);
    //     assertTrue(balanceUsdcCharliePostMint == 0);
    //     uint balanceOzCharliePostMint = ozERC20.balanceOf(charlie);
    //     assertTrue(balanceOzCharliePostMint > 299 * 1 ether && balanceOzCharliePostMint < 300 * 1 ether);
    //     //----------

    //     uint ozAmountIn = 1 * 1 ether; //amountToRedeem = 1
    //     testToken = address(ozERC20);
    //     (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

    //     //Action
    //     vm.startPrank(alice);
    //     ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
    //     uint underlyingOut = ozERC20.burn(req.amtsOut, alice);

    //     //Post-conditions
    //     uint balanceOzBobPostBurn = ozERC20.balanceOf(bob);
    //     uint balanceOzCharliePostBurn = ozERC20.balanceOf(charlie);
    //     uint basisPointsDifferenceBobMEV = (balanceOzBobPostMint - balanceOzBobPostBurn).mulDiv(10000, balanceOzBobPostMint);
    //     uint basisPointsDifferenceCharlieMEV = (balanceOzCharliePostMint - balanceOzCharliePostBurn).mulDiv(10000, balanceOzCharliePostMint);

    //     assertTrue(underlyingOut == IERC20Permit(usdcAddr).balanceOf(alice));
    //     assertTrue(basisPointsDifferenceBobMEV == 0);
    //     assertTrue(basisPointsDifferenceCharlieMEV == 0);
    //     assertTrue(underlyingOut > 999000 && underlyingOut < 1 * 1e6);
    // }


    
    /**
     * Minds ~1M of ozUSDC, but redeems a portion of the balance (~700k)
     */
    // function test_redeeming_bigBalance_bigMint_mediumRedeem() public {
    //     //Pre-conditions
    //     _changeSlippage(9900);
    //     _dealUnderlying(Quantity.BIG);

    //     bytes32 oldSlot0data = vm.load(wethUsdPoolUni, bytes32(0));
    //     (,bytes32 wethBalanceBytes) = _getTokenBalanceFromSlot(wethAddr);

    //     uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
    //     uint amountIn = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
    //     uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
    //     assertTrue(balanceUsdcAlicePostMint == 0);

    //     _resetPoolBalances(oldSlot0data, wethAddr, wethBalanceBytes);

    //     uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
    //     testToken = address(ozERC20);

    //     (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

    //     //Action
    //     vm.startPrank(alice);
    //     ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
    //     uint underlyingOut = ozERC20.burn(req.amtsOut, alice);

    //     //Post-conditions
    //     uint balanceUnderlying = IERC20Permit(usdcAddr).balanceOf(alice);
    //     uint percentageDiffAmounts = (ozAmountIn - (underlyingOut * 1e12)).mulDiv(10000, ozAmountIn);

    //     assertTrue(percentageDiffAmounts < 11);
    //     vm.stopPrank();
    // }



    // function test_redeeming_eip2612() public {
    //     //Pre-conditions
    //     _dealUnderlying(Quantity.SMALL);
    //     uint amountIn = IERC20Permit(testToken).balanceOf(alice); 
    //     assertTrue(amountIn > 0);

    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);

    //     uint ozAmountIn = ozERC20.balanceOf(alice);
    //     testToken = address(ozERC20);
        
    //     (
    //         RequestType memory req,
    //         uint8 v, bytes32 r, bytes32 s
    //     ) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);


    //     //Action
    //     vm.startPrank(alice);
    //     ozERC20.permit(
    //         alice,
    //         address(ozDiamond),
    //         req.amtsOut.ozAmountIn,
    //         block.timestamp,
    //         v, r, s
    //     );

    //     ozERC20.burn(req.amtsOut, alice); 

    //     //Post-conditions
    //     testToken = usdcAddr;
    //     uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
    //     uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);

    //     assertTrue(balanceUnderlyingAlice > 99 * decimalsUnderlying && balanceUnderlyingAlice < 100 * decimalsUnderlying);
    //     assertTrue(ozERC20.totalSupply() == 0);
    //     assertTrue((ozERC20.totalAssets() / decimalsUnderlying) == 0);
    //     assertTrue((ozERC20.totalShares() / decimalsUnderlying) == 0);
    //     assertTrue((ozERC20.sharesOf(alice) / decimalsUnderlying) == 0);
    //     assertTrue((ozERC20.balanceOf(alice) / ozERC20.decimals()) == 0);
    // }


    /**
     * This test proves that rebasing algorithm works, and that the difference
     * between token balances is due to imbalance pools after the test swaps
     */
    // function test_redeeming_multipleBigBalances_bigMint_mediumRedeem() public {
    //     //Pre-conditions
    //     _changeSlippage(9900);
    //     _dealUnderlying(Quantity.BIG);

    //     bytes32 oldSlot0data = vm.load(wethUsdPoolUni, bytes32(0));
    //     (,bytes32 wethBalanceBytes) = _getTokenBalanceFromSlot(wethAddr);

    //     uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
    //     uint amountIn = IERC20Permit(testToken).balanceOf(alice) / 2;
    //     // assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

    //     (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true);
    //     _resetPools(_toWETH(amountIn), oldSlot0data);
    //     console.log('- bal alice oz post-mint - alice & bob same: ', ozERC20.balanceOf(alice));

    //     //-------------------
    //     _createAndMintOzTokens(address(ozERC20), amountIn, bob, BOB_PK, false, false);
    //     _resetPools(_toWETH(amountIn), oldSlot0data);
    //     console.log('- bal bob oz post-mint: ', ozERC20.balanceOf(bob));

    //     //-------------------

    //     uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
    //     testToken = address(ozERC20);

    //     (RequestType memory req,,,) = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

    //     // //Action
    //     vm.startPrank(alice);
    //     ozERC20.approve(address(ozDiamond), req.amtsOut.ozAmountIn);
    //     uint underlyingOut = ozERC20.burn(req.amtsOut, alice);
    //     vm.stopPrank();

    //     // //Post-conditions
    //     console.log('--- post-conditon ---');
    //     console.log('ozAmountIn alice to redeem: ', ozAmountIn);
    //     console.log('usdc out: ', underlyingOut);
    //     console.log('bal alice usdc post-burn: ', IERC20Permit(usdcAddr).balanceOf(alice));

    // }
     



    /************ HELPERS ***********/
  
 

    function _createAndMintOzTokens(
        address testToken_,
        uint amountIn_, 
        address user_, 
        uint userPk_,
        bool create_,
        bool is2612_,
        Type flowType_
    ) private returns(ozIToken ozERC20, uint shares) {
        uint[] memory minAmountsOut;
       
        if (create_) {
            ozERC20 = ozIToken(OZ.createOzToken(
                testToken_, "Ozel-ERC20", "ozERC20"
            ));
        } else {
            ozERC20 = ozIToken(testToken_);
            
        }

        (bytes memory data) = _createDataOffchain(
            ozERC20, amountIn_, userPk_, user_, flowType_
        );

        if (flowType_ == Type.IN) {
            (minAmountsOut,,,) = HelpersTests.extract(data);
        } else {
            //decode for redeeming
        }

        vm.startPrank(user_);

        if (is2612_) {
            _sendPermit(user_, amountIn_, data);
        } else {
            IERC20Permit(testToken).approve(address(ozDiamond), amountIn_);
        }

        AmountsIn memory amounts = AmountsIn(
            amountIn_,
            minAmountsOut[0],
            minAmountsOut[1]
        );

        bytes memory mintData = abi.encode(amounts, user_);
        shares = ozERC20.mint(mintData); 
        
        vm.stopPrank();
    }


//    function _calculateMinWethOut(uint amountIn_) internal view returns(uint minOut) {
//         (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
//         uint expectedOut = amountIn_.mulDivDown(uint(price) * 1e10, ONE_ETHER);
//         minOut = expectedOut - expectedOut.mulDivDown(OZ.getDefaultSlippage(), 10000);
//     }

    function _sendPermit(address user_, uint amountIn_, bytes memory data_) private {
        (,uint8 v, bytes32 r, bytes32 s) = HelpersTests.extract(data_);

        IERC20Permit(testToken).permit(
            user_, 
            address(ozDiamond), 
            amountIn_, 
            block.timestamp, 
            v, r, s
        );
    }


    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint amountIn_,
        uint SENDER_PK_,
        address sender_,
        Type reqType_
    ) private returns(bytes memory data) {
        
        if (reqType_ == Type.OUT) {

            uint shares = ozERC20_.previewWithdraw(amountIn_); //ozAmountIn_
            uint amountInReth = ozERC20_.convertToUnderlying(shares);

            data = HelpersTests.encodeOutData(amountInReth, OZ);

        } else if (reqType_ == Type.IN) { 
            uint[] memory minAmountsOut = HelpersTests.calculateMinAmountsOut(
                [ethUsdChainlink, rEthEthChainlink], amountIn_ / 10 ** IERC20Permit(testToken).decimals(), defaultSlippage
            );

            bytes32 permitHash = _getPermitHash(sender_, amountIn_);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(SENDER_PK_, permitHash);

            data = abi.encode(minAmountsOut, v, r, s);
        }

    }

    
    function _getPermitHash(
        address sender_,
        uint amountIn_
    ) internal view returns(bytes32) {
        return HelpersTests.getPermitHash(
            testToken,
            sender_,
            address(ozDiamond),
            amountIn_,
            IERC20Permit(testToken).nonces(sender_),
            block.timestamp
        );
    }




    //---- Reset pools helpers ----
    function _resetPools(uint amountWeth_, bytes32 slot0data_) private {
        _modifySqrtPriceX96(slot0data_);

        deal(rEthAddr, owner, _toRETH(amountWeth_));
        deal(rEthWethPoolBalancer, owner, _toBPT(amountWeth_), true);

        bytes32 poolId = IPool(rEthWethPoolBalancer).getPoolId();
        address deadAddr = 0x000000000000000000000000000000000000dEaD;

        vm.startPrank(owner);
        IERC20Permit(rEthAddr).approve(vaultBalancer, type(uint).max);

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: poolId,
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(rEthAddr),
            assetOut: IAsset(wethAddr),
            amount: IERC20Permit(rEthAddr).balanceOf(owner),
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: owner,
            fromInternalBalance: false,
            recipient: payable(deadAddr),
            toInternalBalance: false
        });

        IVault(vaultBalancer).swap(singleSwap, funds, 1, block.timestamp);
        
        //---------

        address[] memory assets = Helpers.convertToDynamic([wethAddr, rEthWethPoolBalancer, rEthAddr]);
        uint[] memory minAmountsOut = Helpers.convertToDynamic([uint(1), uint(0), uint(0)]);

        bytes memory userData = Helpers.createUserData(
            IVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, 
            IERC20Permit(rEthWethPoolBalancer).balanceOf(owner), 
            0 
        );

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        IVault(vaultBalancer).exitPool( 
            poolId, 
            owner, 
            payable(deadAddr), 
            request
        );

        vm.stopPrank();
    }

    function _resetPoolBalances(
        bytes32 slot0data_, 
        address token_, 
        bytes32 oldTokenBalance_
    ) private {
        _setTokenBalanceFromSlot(token_, oldTokenBalance_);
        _modifySqrtPriceX96(slot0data_);
    }

    function _modifySqrtPriceX96(bytes32 slot0data_) private {
        bytes12 oldLast12Bytes = bytes12(slot0data_<<160);
        bytes20 oldSqrtPriceX96 = bytes20(slot0data_);

        bytes32 newSlot0Data = bytes32(bytes.concat(oldSqrtPriceX96, oldLast12Bytes));
        vm.store(wethUsdPoolUni, bytes32(0), newSlot0Data);
    }

    function _extractSlot(uint key_, bytes32 pos_, uint offset_) private pure returns(bytes32) {
        return bytes32(uint(keccak256(abi.encodePacked(key_, pos_))) + offset_);
    }

    function _getTokenBalanceFromSlot(address token_) private view returns(bytes32, bytes32) {
        bytes32 poolId = IPool(rEthWethPoolBalancer).getPoolId();
        bytes32 balancesSlot = bytes32(uint(1));

        bytes32 indexesSlot = _extractSlot(uint(poolId), balancesSlot, 2);
        bytes32 tokenIndexSlot = _extractSlot(uint(uint160(token_)), indexesSlot, 0);
        uint tokenIndex = uint(vm.load(vaultBalancer, tokenIndexSlot));

        bytes32 entriesSlot = _extractSlot(uint(poolId), balancesSlot, 1);
        bytes32 tokenBalanceSlot = _extractSlot(uint(tokenIndex - 1), entriesSlot, 1);

        bytes32 tokenBalanceBytes = vm.load(vaultBalancer, tokenBalanceSlot);

        return (tokenBalanceSlot, tokenBalanceBytes);
    }

    function _setTokenBalanceFromSlot(address token_, bytes32 oldTokenBalance_) private {
        (bytes32 tokenBalanceSlot,) = _getTokenBalanceFromSlot(token_);
        vm.store(vaultBalancer, tokenBalanceSlot, oldTokenBalance_);
    }

    function _toWETH(uint amountUnderlying_) private view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(ethUsdChainlink).latestRoundData();
        return amountUnderlying_.mulDiv(ONE_ETHER, uint(price * 1e10));
    }

    function _toRETH(uint amountWeth_) private view returns(uint) {
        (,int price,,,) = AggregatorV3Interface(rEthEthChainlink).latestRoundData();
        return amountWeth_.mulDiv(uint(price), ONE_ETHER);
    }

    function _toBPT(uint amountWeth_) private view returns(uint) {
        uint bptRate = IPool(rEthWethPoolBalancer).getRate();
        return amountWeth_.mulDiv(bptRate, ONE_ETHER);
    }
}