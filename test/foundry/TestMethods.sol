// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/facets/ozTokenFactory.sol";
import {Setup, n} from "./Setup.sol";
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
import {stdMath} from "../../lib/forge-std/src/StdMath.sol";

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
        _runSetup(n);
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
        assertTrue(_checkPercentageDiff(rawAmount * 1 ether, balAlice, 5));
        // assertTrue(balAlice > 98 * 1 ether && balAlice < rawAmount * 1 ether);
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

        uint balanceAlice = ozERC20.balanceOf(alice);
        uint balanceBob = ozERC20.balanceOf(bob);
        uint balanceCharlie = ozERC20.balanceOf(charlie);
    
        assertTrue(_fm(balanceAlice) / 2 == _fm(balanceBob));
        assertTrue(_fm(balanceAlice) / 4 == _fm(balanceCharlie));
        assertTrue(_fm(balanceBob) == _fm(balanceCharlie) * 2);

        assertTrue(_fm4(ozERC20.totalSupply()) == _fm4(balanceAlice) + _fm4(balanceCharlie) + _fm4(balanceBob));
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

        console.log('ozERC20.totalSupply(): ', ozERC20.totalSupply());
        console.log('balancesSum: ', balancesSum);

        assertTrue(_fm5(ozERC20.totalSupply()) == _fm5(balancesSum));
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
        assertTrue(_checkPercentageDiff(rawAmount * 1e18, balAlice, 5));

        uint balBob = ozERC20.balanceOf(bob);
        assertTrue(balBob == 0);

        //Action
        vm.prank(alice);
        ozERC20.transfer(bob, balAlice);

        //Post-conditions
        balAlice = ozERC20.balanceOf(alice);
        assertTrue(balAlice > 0 && balAlice < 0.000001 * 1 ether || balAlice == 0);

        balBob = ozERC20.balanceOf(bob);
        assertTrue(_checkPercentageDiff(rawAmount * 1e18, balBob, 5));
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
        assertTrue(_checkPercentageDiff(1_000_000 * 1e18, balanceOzUsdcAlice, 5));

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
        assertTrue(_checkPercentageDiff(100 * 1e18, ozAmountIn, 5));
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

        /**
         * It's "97" here instead of "99" due to ozAmountIn being "100" instead of "100.02" like in
         * other tests where the full ozToken balance was used, which equaled, on those tests "100.02".
         */
        assertTrue(balanceAliceUnderlying < rawAmount * 10 ** underlyingDecimals && balanceAliceUnderlying > 97 * 10 ** underlyingDecimals);
        assertTrue(balanceAliceUnderlying == underlyingOut);
    }


    /**
     * Use 100 of underlying to mint ozTokens, where redeeming 1 ozTokens, would
     * be ineligble so the MEV produced would be quite lower, proving the efficacy of the 
     * rebase algorithm, without the need of having to rebalance Uniswap and Balancer's pools.
     *
     * In this test, the "bigMint" is in relation to the amount being redeemed (100:1)
     */
    function _redeeming_multipleBigBalances_bigMints_smallRedeem() internal {
        (,uint rawAmountBob, uint rawAmountCharlie) = _dealUnderlying(Quantity.SMALL, false);
        uint amountToRedeem = 2;

        // uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 100 * 10 ** IERC20Permit(testToken).decimals());

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);

        uint balanceOzBobPostMint = _createMintAssertOzTokens(bob, ozERC20, BOB_PK, rawAmountBob);
        uint balanceOzCharliePostMint = _createMintAssertOzTokens(charlie, ozERC20, CHARLIE_PK, rawAmountCharlie);

        uint ozAmountIn = amountToRedeem * 1e18;
        // testToken = address(ozERC20);
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, address(ozERC20), Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData, alice);
        vm.stopPrank();

        //Post-conditions
        uint basisPointsDifferenceBobMEV = (balanceOzBobPostMint - ozERC20.balanceOf(bob)).mulDivDown(10000, balanceOzBobPostMint);
    
        //If diffBalanceCharlieMintRedeem is negative, it means that it wouldn't be profitable to extract MEV from this tx.
        int diffBalanceCharlieMintRedeem = int(balanceOzCharliePostMint) - int(ozERC20.balanceOf(charlie)); 
        uint basisPointsDifferenceCharlieMEV = diffBalanceCharlieMintRedeem <= 0 ? 0 : uint(diffBalanceCharlieMintRedeem).mulDivDown(10000, balanceOzCharliePostMint);

        assertTrue(underlyingOut == IERC20Permit(ozERC20.asset()).balanceOf(alice));
        assertTrue(basisPointsDifferenceBobMEV == 0);
        assertTrue(basisPointsDifferenceCharlieMEV == 0);

        bool amountOutCheck = false;
        uint outReference = (998 * amountToRedeem) * 1e15;

        /**
         * Due to the difference of liquidity between pools, outReference can be slightly off,
         * in comparison to underlyingOut, for less than 3 basis points.
         */
        uint underlyingOut18dec = testToken == usdcAddr ? underlyingOut * 1e12 : underlyingOut;

        if (underlyingOut > outReference || _checkPercentageDiff(outReference, underlyingOut18dec, 3)) {
            amountOutCheck = true;
        }

        assertTrue(amountOutCheck && underlyingOut < amountToRedeem * 10 ** IERC20Permit(testToken).decimals());
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

        /**
         * Measures that the difference between the amount of ozTokens that went in to
         * the amount of underlying that went out is less than N, which translates to
         * differences between pools balances during swaps, where highly liquid pools
         * like ETH/USDC will derived a percentage difference amount of 0.38% (38 bps)
         *  and medium liquid pools like ETH/DAI 3%.
         */
        uint percentageDiffLiquid = 38;
        uint percentageDiffIliquid = 300;

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

        /**
         * Checks that the difference between the amount of ozTokens that went in to be redeemed
         * is less than 0.27% for liquid markets like ETH/USDC, and 1.25% for semi-liquid markets,
         * like ETH/DAI.
         *
         * The difference is bigger (1.38%) when the Balancer rETH-ETH pool is paused because the swap
         * needs to use here Uniswap's rETH-ETH pool instead, which has less liquidity, increasing the 
         * difference margin.
         */
        uint percentageDiffLiquid = 27;
        uint percentageDiffIliquid = 125; 
        uint percentageDiffPaused = 138;

        uint decimals = IERC20Permit(ozERC20.asset()).decimals() == 18 ? 1 : 1e12;
        uint percentageDiffAmounts = (ozAmountIn - (underlyingOut * decimals)).mulDivDown(10000, ozAmountIn);

        assertTrue(
            percentageDiffAmounts < percentageDiffLiquid || 
            percentageDiffAmounts < percentageDiffIliquid ||
            percentageDiffAmounts < percentageDiffPaused
        );
    }
}