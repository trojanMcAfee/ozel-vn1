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

import "forge-std/console.sol";


/**
 * Tests the minting, redeeming, and rebasing logic of the ozToken contract
 * when using Balancer as the logic mechanism. 
 */
contract CoreTokenLogicBALtest is BaseMethods {

    using FixedPointMathLib for uint;



    /**
     * Mints a small quantity of ozUSDC (~100) through a Balancer swap
     */
    function test_minting_approve_smallMint_balancer() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals(); //1e6

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        uint balAlice = ozERC20.balanceOf(alice);
        console.log('oz bal alice: ', balAlice);

        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
        assertTrue(balAlice > 99 * 1 ether && balAlice < rawAmount * 1 ether);
    }


    /**
     * Mints a big quantity of ozTokens (~1M)
     */
    function test_minting_approve_bigMint_balancer() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(9900);

        //Action
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
        );

        //Post-conditions
        uint balAlice = ozERC20.balanceOf(alice);

        assertTrue(address(ozERC20) != address(0));
        assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
        assertTrue(balAlice > 977_000 * 1 ether && balAlice < rawAmount * 1 ether);
    }


    function test_supply_offset() public {
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL); //it seems like the diff is alwats 2 wei. Test this with BIG and SMALL

        // uint[] memory pks = new uint[](10);
        // pks[0] = BOB_PK;
        // pks[1] = CHARLIE_PK;
        // pks[2] = 23545;
        // pks[3] = 46464;
        // pks[4] = 46345;
        // pks[5] = 875785;
        // pks[6] = 2542;
        // pks[7] = 756346;
        // pks[8] = 36235;
        // pks[9] = 46743;

        // address[] memory owners = new address[](10);
        // owners[0] = bob;
        // owners[1] = charlie;
        // owners[2] = vm.addr(pks[2]);
        // owners[3] = vm.addr(pks[3]);
        // owners[4] = vm.addr(pks[4]);
        // owners[5] = vm.addr(pks[5]);
        // owners[6] = vm.addr(pks[6]);
        // owners[7] = vm.addr(pks[7]);
        // owners[8] = vm.addr(pks[8]);
        // owners[9] = vm.addr(pks[9]);

        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, fee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        
        //----------------------
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        uint balAlice = ozERC20.balanceOf(alice);
        console.log('bal oz alice: ', balAlice);
        console.log('shares alice: ', ozERC20.sharesOf(alice));

        //----------------------
        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesBob) = _createAndMintOzTokens(
            address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        uint balBob = ozERC20.balanceOf(bob);
        console.log('bal oz bob: ', balBob);
        console.log('shares bob: ', ozERC20.sharesOf(bob));

        amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesCharlie) = _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        uint balCharlie = ozERC20.balanceOf(charlie);
        console.log('bal oz charlie: ', balCharlie);
        console.log('shares charlie: ', ozERC20.sharesOf(charlie));

        uint PK_4 = 4353465;
        address owner4 = vm.addr(PK_4);
        deal(testToken, owner4, 100 * (10 ** IERC20Permit(testToken).decimals()));
        amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();
        (, uint shares4) = _createAndMintOzTokens(
            address(ozERC20), amountIn, owner4, PK_4, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        // uint bal4 = ozERC20.balanceOf(owner4);
        // console.log('bal oz owner4: ', bal4);
        // console.log('shares owner4: ', ozERC20.sharesOf(owner4));
        //----------------------_


        // for (uint i=1; i<5; i++) {
        //     _mintManyOz(address(ozERC20), rawAmount, i, owners[i-1], pks[i-1]);
            // _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        // }

        // uint sum;

        // uint bal0 = ozERC20.balanceOf(owners[0]);
        // console.log('bal0: ', bal0);
        // uint bal1 = ozERC20.balanceOf(owners[1]);
        // console.log('bal1: ', bal1);
        // uint bal2 = ozERC20.balanceOf(owners[2]);
        // console.log('bal2: ', bal2);

        // for (uint i=0; i<owners.length; i++) {
        //     sum += ozERC20.balanceOf(owners[i]);
        // }

        console.log('********');
        console.log('totalShares: ', ozERC20.totalShares());
        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('totalSum: ', balAlice + balBob + balCharlie);
        // console.log('sum: ', sum);


    }


    function _mintManyOz(
        address ozERC20_, 
        uint rawAmount_, 
        uint i_,
        address owner_,
        uint ownerPK_
    ) internal returns(uint) {
        uint amountIn = (rawAmount_ / i_) * 10 ** IERC20Permit(testToken).decimals();
        (, uint sharesOwner) = _createAndMintOzTokens(
            ozERC20_, amountIn, owner_, ownerPK_, false, true, Type.IN
        );
        return sharesOwner;
    }


    /**
     * Mints a small quantity of ozTokens using EIP2612
     */
    function test_minting_eip2612_balancer() public { 
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, fee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        /**
         * Pre-conditions + Actions (creating of ozTokens)
         */
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);

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

        uint PK_4 = 4353465;
        address owner4 = vm.addr(PK_4);
        deal(testToken, owner4, rawAmount * (10 ** IERC20Permit(testToken).decimals()));
        amountIn = (rawAmount / 3) * 10 ** IERC20Permit(testToken).decimals();
        (, uint shares4) = _createAndMintOzTokens(
            address(ozERC20), amountIn, owner4, PK_4, false, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        // uint PK_5 = 56345;
        // address owner5 = vm.addr(PK_5);
        // deal(testToken, owner5, rawAmount * (10 ** IERC20Permit(testToken).decimals()));
        // amountIn = rawAmount * 2 * 10 ** IERC20Permit(testToken).decimals();
        // (, uint shares5) = _createAndMintOzTokens(
        //     address(ozERC20), amountIn, owner5, PK_5, false, true, Type.IN
        // );
        // _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        //Post-conditions
        // assertTrue(address(ozERC20) != address(0));
        // assertTrue(sharesAlice == rawAmount * ( 10 ** IERC20Permit(testToken).decimals() ));
        // assertTrue(sharesAlice / 2 == sharesBob);
        // assertTrue(sharesAlice / 4 == sharesCharlie);
        // assertTrue(sharesBob == sharesCharlie * 2);
        // assertTrue(sharesBob / 2 == sharesCharlie);

        uint balanceAlice = ozERC20.balanceOf(alice);
        uint balanceBob = ozERC20.balanceOf(bob);
        uint balanceCharlie = ozERC20.balanceOf(charlie);
        uint balance4 = ozERC20.balanceOf(owner4);
        // uint balance5 = ozERC20.balanceOf(owner5);

        // assertTrue(balanceAlice / 2 == balanceBob);
        // assertTrue(balanceAlice / 4 == balanceCharlie);

        console.log('balanceAlice: ', balanceAlice);
        console.log('balanceBob: ', balanceBob);
        console.log('balanceCharlie: ', balanceCharlie);
        console.log('balance4: ', balance4);
        // console.log('balance5: ', balance5);
        console.log('TOTAL: ', balanceAlice + balanceBob + balanceCharlie + balance4);
        console.log('is: ', balanceBob == (balanceCharlie * 2));
        console.log('.');
        // console.log('shares alice: ', sharesAlice);
        // console.log('shares bob: ', sharesBob);
        // console.log('shares charlie: ', sharesCharlie);
        // console.log('shares owner4: ', shares4);
        // console.log('shares owner5: ', shares5);
        // console.log('.');

        // assertTrue(balanceBob == balanceCharlie * 2);

        console.log(13);
        // assertTrue(balanceBob / 2 == balanceCharlie);
        console.log(3);

        //check with other amountsIn if the difference between balances is always 2
        //do timur's advise --> round some calc up, other down - x - can't
        //try with solmate's mulDiv - x
        //try with hex decimals - x
        //try increasing/decreasing decimals - here

        //problem is that with DAI is already top decimals (18 dec)
        //change the precision of ozTokens to 6 instead of 18

        //Error ******
        console.log('totalSupply in test: ', ozERC20.totalSupply());
        console.log('sum in test: ', balanceAlice + balanceCharlie + balanceBob + balance4);

        // assertTrue(ozERC20.totalSupply() == balanceAlice + balanceCharlie + balanceBob);
        // console.log(31);
        // assertTrue(ozERC20.totalAssets() / 10 ** IERC20Permit(testToken).decimals() == rawAmount + rawAmount / 2 + rawAmount / 4);
        // console.log(32);
        // assertTrue(ozERC20.totalShares() == sharesAlice + sharesBob + sharesCharlie);
        // console.log(4);
    }   

    
    /**
     * Transfer ozTokens between accounts
     */
    function test_transfer_balancer() public {
        //Pre-conditions
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);

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
    function test_redeeming_bigBalance_bigMint_bigRedeem_balancer() public {
        //Pre-conditions
        _changeSlippage(9900);
        _dealUnderlying(Quantity.BIG);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(amountIn == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceOzUsdcAlice = ozERC20.balanceOf(alice);
        assertTrue(balanceOzUsdcAlice > 977_000 * 1 ether && balanceOzUsdcAlice < 1_000_000 * 1 ether);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        ozERC20.redeem(redeemData); 

        //Post-conditions
        testToken = ozERC20.asset();
        uint balanceUnderlyingAlice = IERC20Permit(testToken).balanceOf(alice);

        assertTrue(balanceUnderlyingAlice > 998_000 * decimalsUnderlying && balanceUnderlyingAlice < 1_000_000 * decimalsUnderlying);
        assertTrue(ozERC20.balanceOf(alice) == 0);
    }


    /**
     * From 1M underlying balance, mint and redeem a small part (100 USDC)
     */
    function test_redeeming_bigBalance_smallMint_smallRedeem_balancer() public {
        //Pre-conditions
        _changeSlippage(9900);
        _dealUnderlying(Quantity.BIG);

        uint decimalsUnderlying = 10 ** IERC20Permit(testToken).decimals();
        uint amountIn = 100 * decimalsUnderlying;
        assertTrue(IERC20Permit(testToken).balanceOf(alice) == 1_000_000 * decimalsUnderlying);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        uint balanceUsdcAlicePostMint = IERC20Permit(testToken).balanceOf(alice);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        assertTrue(ozAmountIn > 99 * 1 ether && ozAmountIn < 100 * 1 ether);
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData); 

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
    function test_redeeming_bigBalance_bigMint_smallRedeem_balancer() public {
        /**
         * Pre-conditions
         */
        //Deals big amounts of USDC to testers.
        _dealUnderlying(Quantity.BIG);
        uint underlyingDecimals = IERC20Permit(testToken).decimals();
        uint amountIn = IERC20Permit(testToken).balanceOf(alice);
        uint rawAmount = 100;
        assertTrue(amountIn == 1_000_000 * 10 ** underlyingDecimals);

        //Changes the default slippage to 99% so the swaps don't fail.
        _changeSlippage(9900);

        //Gets the pre-swap pool values.
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, fee), 
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
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);
    
        /**
         * Action
         */
        vm.startPrank(alice);

        //Redeems ozTokens for underlying.
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData);
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
    function test_redeeming_multipleBigBalances_bigMints_smallRedeem_balancer() public {
        (,uint initMintAmountBob, uint initMintAmountCharlie) = _dealUnderlying(Quantity.SMALL);
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
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData);

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
    function test_redeeming_bigBalance_bigMint_mediumRedeem_balancer() public {
        //Pre-conditions
        _changeSlippage(9900);
        _dealUnderlying(Quantity.BIG);

        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, fee),
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

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData);

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
    function test_redeeming_eip2612_balancer() public {
        //Pre-conditions
        _dealUnderlying(Quantity.SMALL);
        uint amountIn = IERC20Permit(testToken).balanceOf(alice); 
        assertTrue(amountIn > 0);

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);

        uint ozAmountIn = ozERC20.balanceOf(alice);
        testToken = address(ozERC20);
        
        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, _getPermitHash(alice, ozAmountIn));

        //Action
        vm.startPrank(alice);
        ozERC20.permit(
            alice,
            address(ozDiamond),
            ozAmountIn,
            block.timestamp,
            v, r, s
        );

        ozERC20.redeem(redeemData); 

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
     * between token balances is due to imbalanced pools after the test swaps
     */
    function test_redeeming_multipleBigBalances_bigMint_mediumRedeem_balancer() public {
        //Pre-conditions
        _changeSlippage(9900);
        _dealUnderlying(Quantity.BIG);

        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, fee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        uint amountIn = IERC20Permit(testToken).balanceOf(alice) / 2;

        (ozIToken ozERC20,) = _createAndMintOzTokens(testToken, amountIn, alice, ALICE_PK, true, true, Type.IN);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        _createAndMintOzTokens(address(ozERC20), amountIn, bob, BOB_PK, false, false, Type.IN);
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        uint ozAmountIn = ozERC20.balanceOf(alice) / 10;
        testToken = address(ozERC20);

        bytes memory redeemData = _createDataOffchain(ozERC20, ozAmountIn, ALICE_PK, alice, Type.OUT);

        // //Action
        vm.startPrank(alice);
        ozERC20.approve(address(ozDiamond), ozAmountIn);
        uint underlyingOut = ozERC20.redeem(redeemData);
        vm.stopPrank();

        // //Post-conditions
        uint percentageDiffLiquid = 15;
        uint percentageDiffIliquid = 37;
        uint decimals = IERC20Permit(ozERC20.asset()).decimals() == 18 ? 1 : 1e12;
        uint percentageDiffAmounts = (ozAmountIn - (underlyingOut * decimals)).mulDivDown(10000, ozAmountIn);

        assertTrue(percentageDiffAmounts < percentageDiffLiquid || percentageDiffAmounts < percentageDiffIliquid);
    }
}