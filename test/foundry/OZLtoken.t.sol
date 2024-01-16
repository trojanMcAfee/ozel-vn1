// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";
import {IWETH} from "../../contracts/interfaces/IWETH.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {FixedPointMathLib} from "../../contracts/libraries/FixedPointMathLib.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {Type} from "./AppStorageTests.sol";
import {IRocketTokenRETH} from "../../contracts/interfaces/IRocketPool.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {QuoteAsset} from "../../contracts/interfaces/IOZL.sol";
import {HelpersLib} from "./HelpersLib.sol";
import {IVault, IAsset, IPool, IQueries} from "../../contracts/interfaces/IBalancer.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";


import "forge-std/console.sol";


contract OZLtokenTest is TestMethods {

    using FixedPointMathLib for uint;


   function _mock_rETH_ETH() internal {
        uint bpsIncrease = 400; //92 - 400
        uint rETHETHmock = OZ.rETH_ETH() + bpsIncrease.mulDivDown(OZ.rETH_ETH(), 10_000);

        vm.mockCall( 
            address(rEthEthChainlink),
            abi.encodeWithSignature('latestRoundData()'),
            abi.encode(uint80(0), int(rETHETHmock), uint(0), uint(0), uint80(0))
        ); 
    }

    
    //-------

    function test_chargeOZLfee_noFeesToDistribute() public {
        //Pre-condtion
        _minting_approve_smallMint();

        //Action
        bool wasCharged = OZ.chargeOZLfee();

        //Post-condition
        assertTrue(!wasCharged);
    }

    // function test_exchangeRate_no_circulatingSupply

    
    function _checkChargeFeeClaimOZL(IOZL OZL) internal returns(uint ozlBalanceAlice) {
        uint ozlBalancePre = OZL.balanceOf(alice);
        assertTrue(ozlBalancePre == 0);

        uint pendingOZLallocPre = OZ.pendingAllocation();
        assertTrue(communityAmount == pendingOZLallocPre);

         bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        uint circulatingSupply = OZ.getCirculatingSupply();
        assertTrue(circulatingSupply == 0);

        vm.prank(alice);
        uint claimedReward = OZ.claimReward();

        circulatingSupply = OZ.getCirculatingSupply();
        assertTrue(circulatingSupply > 0);

        ozlBalanceAlice = OZL.balanceOf(alice);
        assertTrue(ozlBalanceAlice > 0);

        uint pendingOZLallocPost = OZ.pendingAllocation();
        assertTrue(claimedReward ==  pendingOZLallocPre - pendingOZLallocPost);

        uint recicledSupply = OZ.getRecicledSupply();
        assertTrue(recicledSupply == 0);
    }


    function test_x() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        _startCampaign();
        _mintOzTokens(ozERC20, alice, amountIn); 

        uint secs = 10 + campaignDuration; //campaignDuration
        vm.warp(block.timestamp + secs);

        int durationLeft = OZ.durationLeft();
        assertTrue(durationLeft < 0);

        _mock_rETH_ETH();

        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlBalanceAlice = _checkChargeFeeClaimOZL(OZL);

        //Actions

        //-- params for redeem ---
        uint wethToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.ETH)) / 1 ether;

        _changeSlippage(uint16(500)); //500 - 5% / 50 - 0.5% 

        uint minAmountOutWeth = HelpersLib.calculateMinAmountOut(wethToRedeem, OZ.getDefaultSlippage());

        uint[] memory minAmountsOut = new uint[](1);
        minAmountsOut[0] = minAmountOutWeth;

        uint ozlBalanceOZLPreRedeem = OZL.balanceOf(address(OZL));

        uint pendingAllocPreRedeem = OZ.pendingAllocation();
        assertTrue(pendingAllocPreRedeem < (1 * 1e18) / 1000000);

        vm.startPrank(alice);
        OZL.approve(address(OZL), ozlBalanceAlice);

        //------
    
        OZL.redeem(
            alice,
            alice,
            wethAddr,
            ozlBalanceAlice,
            minAmountsOut
        );
        vm.stopPrank();

        uint pendingAllocPostRedeem = OZ.pendingAllocation();
        assertTrue(pendingAllocPreRedeem == pendingAllocPostRedeem);

        uint ozlBalanceOZPostRedeem = OZL.balanceOf(address(OZ));
        assertTrue(ozlBalanceOZPostRedeem == communityAmount);

        uint oldRecicledSupply = OZ.getRecicledSupply();
        assertTrue(oldRecicledSupply == ozlBalanceAlice);

        uint oldRewardRate = OZ.getRewardRate();

        //Actions
        uint oneYear = 31560000;
        vm.prank(owner);
        OZ.startNewReciclingCampaign(oneYear); //one year

        //Post-conditions
        uint newRewardRate = OZ.getRewardRate();

        assertTrue(oldRewardRate != newRewardRate);
        assertTrue(oldRecicledSupply / oneYear == newRewardRate);
        assertTrue(OZ.getRecicledSupply() == 0);
    }


    function test_recicled_supply() public {
        //Pre-conditions
        test_claim_OZL();

        IOZL OZL = IOZL(address(ozlProxy));

        uint ozlBalanceAlice = OZL.balanceOf(alice);
        assertTrue(ozlBalanceAlice > 0);

        uint recicledSupply = OZ.getRecicledSupply();
        assertTrue(recicledSupply == 0);

        uint rEthBalanceAlice = IERC20Permit(rEthAddr).balanceOf(alice);
        assertTrue(rEthBalanceAlice == 0);

        uint rEthToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.rETH)) / 1 ether;

        uint[] memory minAmountsOut = new uint[](1);
        minAmountsOut[0] = HelpersLib.calculateMinAmountOut(
            rEthToRedeem, 
            OZ.getDefaultSlippage()
        );

        //Actions
        vm.startPrank(alice);
        approve(OZL, ozlBalanceAlice);

        OZL.redeem(
            alice,
            alice,
            rEthAddr,
            ozlBalanceAlice,
            minAmountsOut
        );
        vm.stopPrank();

        //Post-condtions
        rEthBalanceAlice = IERC20Permit(rEthAddr).balanceOf(alice);
        assertTrue(rEthBalanceAlice > 0);

        recicledSupply = OZ.getRecicledSupply();
        assertTrue(recicledSupply > 0);
        assertTrue(recicledSupply == ozlBalanceAlice);

        ozlBalanceAlice = OZL.balanceOf(alice);
        assertTrue(ozlBalanceAlice == 0);
    }


    //Test the claiming process of OZL.
    //Also checks the pending allocation of OZL. 
    //Checks circulatingSupply
    function test_claim_OZL() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        _startCampaign();
        _mintOzTokens(ozERC20, alice, amountIn); 

        uint secs = 10;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        IOZL OZL = IOZL(address(ozlProxy));
        uint ozlBalancePre = OZL.balanceOf(alice);
        assertTrue(ozlBalancePre == 0);

        uint pendingOZLallocPre = OZ.pendingAllocation();
        assertTrue(communityAmount == pendingOZLallocPre);

        //Actions
        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        uint circulatingSupply = OZ.getCirculatingSupply();
        assertTrue(circulatingSupply == 0);

        vm.prank(alice);
        uint claimedReward = OZ.claimReward();

        //Post-condtions
        circulatingSupply = OZ.getCirculatingSupply();
        assertTrue(circulatingSupply > 0);

        uint ozlBalancePost = OZL.balanceOf(alice);
        assertTrue(ozlBalancePost > 0);
        assertTrue(circulatingSupply == ozlBalancePost);

        uint pendingOZLallocPost = OZ.pendingAllocation();
        assertTrue(claimedReward ==  pendingOZLallocPre - pendingOZLallocPost);
    }



    function test_redeem_in_rETH() public {
        //Pre-conditions
        test_claim_OZL();

        IOZL OZL = IOZL(address(ozlProxy));

        uint ozlBalanceAlice = OZL.balanceOf(alice);
        uint rEthBalancePre = IERC20Permit(rEthAddr).balanceOf(alice);
        assertTrue(rEthBalancePre == 0);
        
        uint rEthToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.rETH)) / 1 ether;
        _changeSlippage(uint16(5)); //0.05%
        uint minAmountOutReth = HelpersLib.calculateMinAmountOut(rEthToRedeem, OZ.getDefaultSlippage());

        uint[] memory minAmountsOut = new uint[](1);
        minAmountsOut[0] = minAmountOutReth;

        //Action
        vm.startPrank(alice);
        approve(OZL, ozlBalanceAlice);

        uint amountOut = OZL.redeem(
            alice,
            alice,
            rEthAddr,
            ozlBalanceAlice,
            minAmountsOut
        );
        vm.stopPrank();

        //Post-condition
        uint rEthBalancePost = IERC20Permit(rEthAddr).balanceOf(alice);
        
        assertTrue(rEthBalancePost > 0);
        assertTrue(amountOut == rEthBalancePost);
    } 


    /**
     * This tests, and redeem_in_stable requires such a hight slippage for WETH 
     * because it's reflecting the incresae in the rate of rETH_ETH done by the mock call.
     * The rETH-WETH Balancer pool doesn't recognize this increase so it's outputting
     * a value based on the actual rETH-WETH rate, instead of the mocked one.
     */
    function test_redeem_in_WETH_ETH() public {
        //Pre-conditions
        test_claim_OZL();

        IOZL OZL = IOZL(address(ozlProxy));

        uint ozlBalanceAlice = OZL.balanceOf(alice);

        uint wethBalancePre = IWETH(wethAddr).balanceOf(alice);
        assertTrue(wethBalancePre == 0);

        uint wethToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.ETH)) / 1 ether;

        _changeSlippage(uint16(500)); //500 - 5% / 50 - 0.5% 

        uint minAmountOutWeth = HelpersLib.calculateMinAmountOut(wethToRedeem, OZ.getDefaultSlippage());

        uint[] memory minAmountsOut = new uint[](1);
        minAmountsOut[0] = minAmountOutWeth;

        //Action
        vm.startPrank(alice);
        OZL.approve(address(OZL), ozlBalanceAlice);

        uint amountOut = OZL.redeem(
            alice,
            alice,
            wethAddr,
            ozlBalanceAlice,
            minAmountsOut
        );

        vm.stopPrank();
        
        //Post-condition
        uint wethBalancePost = IWETH(wethAddr).balanceOf(alice);
        assertTrue(wethBalancePost > 0);
        assertTrue(wethBalancePost == amountOut);
    }


    function test_redeem_permit_in_stable() public {
        //Pre-conditions
        test_claim_OZL();

        IOZL OZL = IOZL(address(ozlProxy));

        uint balanceAlicePre = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceAlicePre == 0);

        uint ozlBalanceAlice = OZL.balanceOf(alice);
        uint usdToRedeem = ozlBalanceAlice * OZL.getExchangeRate() / 1 ether;

        _changeSlippage(uint16(500)); //500 - 5% / 50 - 0.5%  / 100 - 1%

        uint wethToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.ETH)) / 1 ether;

        uint[] memory minAmountsOut = HelpersLib.calculateMinAmountsOut(
            [wethToRedeem, usdToRedeem], [OZ.getDefaultSlippage(), uint16(50)]
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, _getPermitHashOZL(alice, address(OZL), ozlBalanceAlice));
        
        vm.startPrank(alice);
        OZL.permit(
            alice,
            address(OZL),
            ozlBalanceAlice,
            block.timestamp,
            v, r, s
        );

        uint amountOut = OZL.redeem(
            alice,
            alice,
            daiAddr,
            ozlBalanceAlice,
            minAmountsOut
        );

        vm.stopPrank();

        //Post-condtions
        uint balanceAlicePost = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceAlicePost == amountOut);
    }


    function test_redeem_in_stable() public {
        //Pre-conditions
        test_claim_OZL();

        IOZL OZL = IOZL(address(ozlProxy));

        uint balanceAlicePre = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceAlicePre == 0);

        uint ozlBalanceAlice = OZL.balanceOf(alice);
        uint usdToRedeem = ozlBalanceAlice * OZL.getExchangeRate() / 1 ether;

        _changeSlippage(uint16(500)); //500 - 5% / 50 - 0.5%  / 100 - 1%

        uint wethToRedeem = (ozlBalanceAlice * OZL.getExchangeRate(QuoteAsset.ETH)) / 1 ether;

        uint[] memory minAmountsOut = HelpersLib.calculateMinAmountsOut(
            [wethToRedeem, usdToRedeem], [OZ.getDefaultSlippage(), uint16(50)]
        );

        //Action
        vm.startPrank(alice);
        OZL.approve(address(OZL), ozlBalanceAlice);

        uint amountOut = OZL.redeem(
            alice,
            alice,
            daiAddr,
            ozlBalanceAlice,
            minAmountsOut
        );

        vm.stopPrank();

        //Post-condtions
        uint balanceAlicePost = IERC20Permit(testToken).balanceOf(alice);
        assertTrue(balanceAlicePost == amountOut);
    }


    //-----
    function test_redeem_x() public {
        test_redeem_in_stable();

        uint pendingOZLallocPostRedeem = OZ.pendingAllocation();
        console.log('pendingOZLalloc - post OZL redeem: ', pendingOZLallocPostRedeem);

    }

    //-------------

    function test_redeem_in_WETH_paused_pool() public pauseBalancerPool {
        test_redeem_in_WETH_ETH();
    }


    function test_exchangeRate_with_circulatingSupply() public {
        //Pre-condition
        test_claim_OZL();

        //Actions
        IOZL OZL = IOZL(address(ozlProxy));

        uint rateUsd = OZL.getExchangeRate(QuoteAsset.USD);
        uint rateEth = OZL.getExchangeRate(QuoteAsset.ETH);
        uint rateReth = OZL.getExchangeRate(QuoteAsset.rETH);

        //Post-conditions
        uint diffUSDETH = _getRateDifference(rateUsd, rateEth, OZ.ETH_USD());
        uint diffETHRETH = _getRateDifference(rateEth, rateReth, OZ.rETH_ETH());

        assertTrue(diffUSDETH == 0);
        assertTrue(diffETHRETH == 0);
    }


    function test_chargeOZLfee_distributeFees() public { 
        /**
         * Pre-conditions
         */
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);

        /**
         * Actions
         */

         //ALICE
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        (ozIToken ozERC20,) = _createAndMintOzTokens(
            testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
        );
        _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

        //BOB
        amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        _mintOzTokens(ozERC20, bob, amountIn);

        _mock_rETH_ETH();

        //Charges fee
        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        uint ozlRethBalance = IERC20Permit(rEthAddr).balanceOf(address(ozlProxy));

        /**
         * Post-conditions
         */
        uint pastCalculatedRewardsETH = OZ.getLastRewards().prevTotalRewards; 
        uint ozelFeesETH = OZ.getProtocolFee().mulDivDown(pastCalculatedRewardsETH, 10_000);
        uint netOzelFeesETH = ozelFeesETH - uint(50).mulDivDown(ozelFeesETH, 10_000);

        uint ozelFeesRETH = netOzelFeesETH.mulDivDown(1 ether, OZ.rETH_ETH());
        uint feesDiff = ozlRethBalance - ozelFeesRETH;
        assertTrue(feesDiff <= 1 && feesDiff >= 0);

        uint ownerBalance = IERC20Permit(rEthAddr).balanceOf(owner);
        assertTrue(ownerBalance > 0);

        vm.clearMockedCalls();
    }  






    //---------

    //** this function represents the notes in chargeOZLfee() (will fail) */
    function test_exchangeRate_edge_case() internal {
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20"
        ));

        (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        _startCampaign();
        _mintOzTokens(ozERC20, alice, amountIn); 

        uint secs = 10;
        vm.warp(block.timestamp + secs);

        _mock_rETH_ETH();

        _dealUnderlying(Quantity.BIG);
        _mintOzTokens(ozERC20, alice, amountIn); //<-- part the makes this function fail

        bool wasCharged = OZ.chargeOZLfee();
        assertTrue(wasCharged);

        vm.prank(alice);
        OZ.claimReward();

        //-----
        IOZL OZL = IOZL(address(ozlProxy));

        uint rate = OZL.getExchangeRate(QuoteAsset.USD);
        console.log('rate3: ', rate);
    }


    function _getRateDifference(
        uint baseRate_, 
        uint quoteRate_,
        uint exchangeRate_
    ) internal pure returns(uint) {
        return baseRate_ / 1000 - ((quoteRate_ * exchangeRate_) / 1 ether) / 1000;
    }
}