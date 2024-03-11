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
import {HelpersLib} from "./HelpersLib.sol";
// import "solady/src/utils/FixedPointMathLib.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {Type, RequestType, ReqIn, ReqOut} from "./AppStorageTests.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {ozToken} from "../../contracts/ozToken.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {BaseMethods} from "./BaseMethods.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IRocketStorage} from "../../contracts/interfaces/IRocketPool.sol";

import "forge-std/console.sol";


/**
 * Tests the minting, redeeming, and rebasing logic of the ozToken contract
 * when using Balancer as the logic mechanism. 
 */
contract TestMethods is BaseMethods {

    using FixedPointMathLib for uint;


    modifier pauseBalancerPool() {
        vm.mockCall(
            rEthWethPoolBalancer,
            abi.encodeWithSignature('getPausedState()'),
            abi.encode(true, uint(0), uint(0))
        );

        _;

        (bool paused,,) = IPool(rEthWethPoolBalancer).getPausedState();
        assertTrue(paused);
        vm.clearMockedCalls();
    }

    modifier rollBlockAndState() {
        vm.rollFork(secondaryBlockNumber);
        _runSetup();
        vm.mockCall(
            IRocketStorage(rocketPoolStorage)
                .getAddress(keccak256(abi.encodePacked("contract.address", "rocketDAOProtocolSettingsDeposit"))),
            abi.encodeWithSignature('getMaximumDepositPoolSize()'),
            abi.encode(uint(0))
        );
        _;
        vm.rollFork(mainBlockNumber);
        vm.clearMockedCalls();
    }


    /**
     * Mints a small quantity of ozUSDC (~100) through a Balancer swap
     */
    function _minting_approve_smallMint() internal {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();        

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        uint balAlice = ozERC20.balanceOf(alice);

        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * SHARES_DECIMALS_OFFSET);
        assertTrue(balAlice > 98 * 1 ether && balAlice < rawAmount * 1 ether);
    }

    
    /**
     * Mints a big quantity of ozTokens (~1M)
     */
    function _minting_approve_bigMint() internal {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        uint balAlice = ozERC20.balanceOf(alice);

        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * SHARES_DECIMALS_OFFSET);
        assertTrue(_checkPercentageDiff(rawAmount * 1 ether, balAlice, 5));
        // assertTrue(balAlice > 977_000 * 1 ether && balAlice < rawAmount * 1 ether);
    }



    /**
     * Mints a small quantity of ozTokens using EIP2612 with a few users, and then
     * cross-check between them the main rebasing variables from the ozToken
     * (totalSupply, totalShares, totalAssets)
     */
    function _minting_eip2612() internal { 
        /**
         * Pre-conditions + Actions (creating of ozTokens)
         */
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);

        /**
         * Actions
         */
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesBob) = _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);


        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * SHARES_DECIMALS_OFFSET);
        assertTrue(sharesAlice / 2 == sharesBob);
        assertTrue(sharesAlice / 4 == sharesCharlie);
        assertTrue(sharesBob == sharesCharlie * 2);
        assertTrue(sharesBob / 2 == sharesCharlie);

        uint balanceAlice = _fm(ozERC20.balanceOf(alice));
        uint balanceBob = _fm(ozERC20.balanceOf(bob));
        uint balanceCharlie = _fm(ozERC20.balanceOf(charlie));
    
        assertTrue(balanceAlice / 2 == balanceBob);
        assertTrue(balanceAlice / 4 == balanceCharlie);
        assertTrue(balanceBob == balanceCharlie * 2);

        assertTrue(_fm(ozERC20.totalSupply()) == balanceAlice + balanceCharlie + balanceBob);
        assertTrue(ozERC20.totalAssets() == (rawAmount + rawAmount / 2 + rawAmount / 4) * 1e6);
        assertTrue(ozERC20.totalShares() == sharesAlice + sharesBob + sharesCharlie);
    }   

    /**
     * Tests the constraint that the sum of balances between all holders is equal to
     * calling the totalSupply function of the ozToken contracts.
     */
    function _ozToken_supply() internal { 
        //Pre-conditions
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        _changeSlippage(uint16(9900));

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG, false);

        //Actions
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        (address[] memory owners, uint[] memory PKs) = _getOwners(rawAmount);

        for (uint i=0; i<owners.length; i++) {
            _mintManyOz(address(ozERC20), rawAmount, i+1, owners[i], PKs[i]);
            _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        }

        //Post-conditions
        uint balancesSum;
        uint sharesSum;

        for (uint i=0; i<owners.length; i++) {
            balancesSum += ozERC20.balanceOf(owners[i]);
            sharesSum += ozERC20.sharesOf(owners[i]);
        }

        balancesSum += ozERC20.balanceOf(alice);
        sharesSum += sharesAlice;

        assertTrue(_fm(ozERC20.totalSupply()) == _fm(balancesSum));
        assertTrue(ozERC20.totalShares() == sharesSum);
    } 

    
    /**
     * Transfer ozTokens between accounts
     */
    function _transfer() internal {
        //Pre-conditions
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);

        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
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
        assertTrue(balAlice > 0 && balAlice < 0.000001 * 1 ether || balAlice == 0);

        balBob = ozERC20.balanceOf(bob);
        assertTrue(balBob > 99 * 1 ether && balBob < rawAmount * 1 ether);
    }

    /**
     * From 1M underlying balance, mint 1M and redeem 1M
     */
    function _redeeming_bigBalance_bigMint_bigRedeem() internal {
        //Pre-conditions
        _changeSlippage(uint16(9900));
        _dealUnderlying(Quantity.BIG, false);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceOzUsdcAlice = ozERC20.balanceOf(alice);
        assertTrue(balanceOzUsdcAlice > 977_000 * 1 ether && balanceOzUsdcAlice < 1_000_000 * 1 ether);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(
            ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT
        );

        uint assetsPre = ozERC20.totalAssets();
        uint sharesPre = ozERC20.totalShares();
        assertTrue(assetsPre > 0 && sharesPre > 0);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        ozERC20.redeem(redeemData, alice); 

        //Post-conditions
        uint assetsPost = ozERC20.totalAssets();
        uint sharesPost = ozERC20.totalShares();
        assertTrue(assetsPost == 0 && sharesPost == 0);

        testToken = ozERC20.asset();
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);

        assertTrue(balanceUnderlyingAlice > 997_000 * decimalsUnderlying && balanceUnderlyingAlice < 1_000_000 * decimalsUnderlying);
        assertTrue(ozERC20.balanceOf(alice) == 0);
    }


    /**
     * From 1M underlying balance, mint and redeem a small part (100 USDC)
     */
    function _redeeming_bigBalance_smallMint_smallRedeem() internal {
        //Pre-conditions
        _changeSlippage(uint16(9900));
        _dealUnderlying(Quantity.BIG, false);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = 100 * decimalsUnderlying;
        assertTrue(IERC20Permit(testToken).balanceOf(alice) == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        assertTrue(ozAmountIn > 99 * 1 ether && ozAmountIn < 100 * 1 ether);
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData, alice); 

        //Post-conditions
        testToken = ozERC20.asset();
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);
        uint finalUnderlyingNetBalanceAlice = balanceUsdcAlicePostMint + underlyingOut;
        
        assertTrue(ozERC20.balanceOf(alice) == 0);
        assertTrue(underlyingOut > 99 * decimalsUnderlying && underlyingOut < 100 * decimalsUnderlying);
        assertTrue(balanceUnderlyingAlice == finalUnderlyingNetBalanceAlice);
        assertTrue(finalUnderlyingNetBalanceAlice > 999_000 * decimalsUnderlying && finalUnderlyingNetBalanceAlice < 1_000_000 * decimalsUnderlying);
    }


    /** REFERENCE
     * Mints 1M of ozTokens, then rebalances Uniswap and Balancer pools, 
     * and redeems a small portion of ozTokens. 
     */
    function _redeeming_bigBalance_bigMint_smallRedeem() internal {
        /**
         * Pre-conditions
         */
        //Deals big amounts of USDC to testers.
        _dealUnderlying(Quantity.BIG, false);
        uint underlyingDecimals = IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        uint rawAmount = 100;
        assertTrue(amountIn == 1_000_000 * 10 ** underlyingDecimals);

        //Changes the default slippage to 99% so the swaps don't fail.
        _changeSlippage(uint16(9900));

        //Gets the pre-swap pool values.
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        //Creates an ozToken and mints some.
        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);

        //Returns balances to pre-swaps state so the rebase algorithm can be prorperly tested.
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        uint ozAmountIn = rawAmount * 1 ether;
        testToken = address(ozERC20);

        //Creates offchain the token-amount variables needed for safe protocol execution.
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT);

        /**
         * Action
         */
        vm.startPrank(alice);

        //Redeems ozTokens for underlying.
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData, alice);
        vm.stopPrank();

        /**
         * Post-conditions
         */
        testToken = ozERC20.asset();
        uint balanceAliceUnderlying = IERC20Permit(testToken).balanceOf(alice);

        assertTrue(balanceAliceUnderlying < rawAmount * 10 ** underlyingDecimals && balanceAliceUnderlying > 99 * 10 ** underlyingDecimals);
        assertTrue(balanceAliceUnderlying == underlyingOut);
    }


    /**
     * Used 100 of underlying to mint ozTokens, where redeeming 1 ozTokens, would
     * be ineligble so the MEV produced would be quite lower, proving the efficacy of the 
     * rebase algorithm, without the need of having to rebalance Uniswap and Balancer's pools.
     *
     * In this test, the "bigMint" is in relation to the amount being redeem (100:1)
     */
    function _redeeming_multipleBigBalances_bigMints_smallRedeem() internal {
        (,uint initMintAmountBob, uint initMintAmountCharlie) = _dealUnderlying(Quantity.SMALL, false);
        uint amountToRedeem = 1;

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 100 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0); 

        uint balanceOzBobPostMint = _createMintAssertOzTokens(bob, ozERC20, BOB_PK, initMintAmountBob);
        uint balanceOzCharliePostMint = _createMintAssertOzTokens(charlie, ozERC20, CHARLIE_PK, initMintAmountCharlie);

        uint ozAmountIn = amountToRedeem * 1 ether;
        testToken = address(ozERC20);
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData, alice);

        //Post-conditions
        uint balanceOzBobPostRedeem = ozERC20.balanceOf(bob);
        uint balanceOzCharliePostRedeem = ozERC20.balanceOf(charlie);
        uint basisPointsDifferenceBobMEV = (balanceOzBobPostMint - balanceOzBobPostRedeem).mulDivDown(10000, balanceOzBobPostMint);
        testToken = ozERC20.asset();
        
        //If diffBalanceCharlieMintRedeem is negative, it means that it wouldn't be profitable to extract MEV from this tx.
        int diffBalanceCharlieMintRedeem = int(balanceOzCharliePostMint) - int(balanceOzCharliePostRedeem); 
        uint basisPointsDifferenceCharlieMEV = diffBalanceCharlieMintRedeem <= 0 ? 0 : uint(diffBalanceCharlieMintRedeem).mulDivDown(10000, balanceOzCharliePostMint);

        assertTrue(underlyingOut == IERC20Permit(testToken).balanceOf(alice));
        assertTrue(basisPointsDifferenceBobMEV == 0);
        assertTrue(basisPointsDifferenceCharlieMEV == 0);
        assertTrue(underlyingOut > 998_000 && underlyingOut < 1 * decimalsUnderlying);
    }


    
    /**
     * Mints ~1M of ozTokens, but redeems a portion of the balance.
     */
    function _redeeming_bigBalance_bigMint_mediumRedeem() internal {
        //Pre-conditions
        _changeSlippage(uint16(9900));
        _dealUnderlying(Quantity.BIG, false);

        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee),
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        uint underlyingDecimals = IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * 10 ** underlyingDecimals);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceUsdcAlicePostMint == 0);

        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData, alice);

        //Post-conditions
        uint decimals = IERC20Permit(ozERC20.asset()).decimals() == 18 ? 1 : 1e12;
        uint percentageDiffAmounts = (ozAmountIn - (underlyingOut * decimals)).mulDivDown(10000, ozAmountIn);

        //Measures that the difference between the amount of ozTokens that went in to
        //the amount of underlying that went out is less than 0.15%, which translates to
        //differences between pools balances during swaps. 
        /**
         * Measures that the difference between the amount of ozTokens that went in to
         * the amount of underlying that went out is less than N, which translates to
         * differences between pools balances during swaps, where highly liquid pools
         * like ETH/USDC will derived a percentage difference amount of 0.15% (15 bps)
         *  and medium liquid pools like ETH/DAI 0.36%.
         */
        uint percentageDiffLiquid = 15;
        uint percentageDiffIliquid = 37;
        assertTrue(percentageDiffAmounts < percentageDiffLiquid || percentageDiffAmounts < percentageDiffIliquid);
        vm.stopPrank();
    }

    /**
     * Tests redeeming ozTokens for underlying using Permit.
     */
    function _redeeming_eip2612() internal {
        //Pre-conditions
        _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = IERC20Permit(testToken).balanceOf(alice); 
        assertTrue(amountIn > 0);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);
        
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, _getPermitHash(alice, address(ozDiamond), ozAmountIn));

        //Action
        vm.startPrank(alice);
        ozERC20.permit(
            alice,
            address(ozDiamond),
            ozAmountIn,
            block.timestamp,
            v, r, s
        );

        ozERC20.redeem(redeemData, alice); 

        //Post-conditions
        testToken = ozERC20.asset();
        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);

        assertTrue(balanceUnderlyingAlice > 99 * decimalsUnderlying && balanceUnderlyingAlice < 100 * decimalsUnderlying);
        assertTrue(ozERC20.totalSupply() == 0);
        assertTrue((ozERC20.totalAssets() / decimalsUnderlying) == 0);
        assertTrue((ozERC20.totalShares() / decimalsUnderlying) == 0);
        assertTrue((ozERC20.sharesOf(alice) / decimalsUnderlying) == 0);
        assertTrue((ozERC20.balanceOf(alice) / ozERC20.decimals()) == 0);
    }


    /**
     * This test proves that the rebasing algorithm works, and that the difference
     * between token balances is due to imbalanced pools after the test swaps.
     */
    function _redeeming_multipleBigBalances_bigMint_mediumRedeem() internal {
        //Pre-conditions
        _changeSlippage(uint16(9900));
        _dealUnderlying(Quantity.BIG, false);

        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        uint amountIn = IERC20Permit(testToken).balanceOf(alice) / 2;

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        _createAndMintOzTokens(address(ozERC20), amountIn / 2, bob, BOB_PK, false, false, Type.IN);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, testToken, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData, alice);
        vm.stopPrank();

        //Post-conditions
        uint percentageDiffLiquid = 15;
        uint percentageDiffIliquid = 37;
        uint percentageDiffPaused = 44;

        uint decimals = IERC20Permit(ozERC20.asset()).decimals() == 18 ? 1 : 1e12;
        uint percentageDiffAmounts = (ozAmountIn - (underlyingOut * decimals)).mulDivDown(10000, ozAmountIn);

        assertTrue(
            percentageDiffAmounts < percentageDiffLiquid || 
            percentageDiffAmounts < percentageDiffIliquid ||
            percentageDiffAmounts < percentageDiffPaused
        );

        console.log('');
        console.log('shares alice: ', ozERC20.sharesOf(alice));
        console.log('shares bob: ', ozERC20.sharesOf(bob));
        console.log('oz bal alice: ', ozERC20.balanceOf(alice));
        console.log('oz bal bob: ', ozERC20.balanceOf(bob));
        console.log('totalShares: ', ozERC20.totalShares());
        // console.log('totalAssets)
    }
}