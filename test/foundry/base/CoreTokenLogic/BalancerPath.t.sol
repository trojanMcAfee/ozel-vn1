// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {TestMethods} from "../TestMethods.sol";
import {FixedPointMathLib} from "../../../../contracts/libraries/FixedPointMathLib.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

//--------
import {IERC20Permit} from "./../../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "./../../../../contracts/interfaces/ozIToken.sol";
import {IAave} from "./../../../../contracts/interfaces/IAave.sol";
import {IVault, IPool, IAsset} from "./../../../../contracts/interfaces/IBalancer.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AmountsIn} from "./../../../../contracts/AppStorage.sol";


import "forge-std/console.sol";


contract BalancerPathTest is TestMethods {

    using FixedPointMathLib for uint;


    function _constructUniSwap(uint amountIn_) private view returns(ISwapRouter.ExactInputSingleParams memory) {
        return ISwapRouter.ExactInputSingleParams({ 
                tokenIn: wethAddr,
                tokenOut: testToken, 
                fee: uniPoolFee, 
                recipient: address(OZ),
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
    }


    function _constructBalancerSwap() private view returns(
        IVault.SingleSwap memory, 
        IVault.FundManagement memory
    ) {

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: IPool(rEthWethPoolBalancer).getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(rEthAddr),
            assetOut: IAsset(wethAddr),
            amount: 946135001651163,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(OZ),
            fromInternalBalance: false, 
            recipient: payable(address(OZ)),
            toInternalBalance: false
        });

        return (singleSwap, funds);
    }


    function test_strategy_new() public {
        //Pre-condition
        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, false);
        uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();   
        console.log('amountInStable in test: ', amountIn);

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");

        bytes memory mintData = OZ.getMintData(amountIn, OZ.getDefaultSlippage(), alice, address(ozERC20));
        (AmountsIn memory amts,) = abi.decode(mintData, (AmountsIn, address));

        payable(alice).transfer(1000 ether);

        vm.startPrank(alice);

        IERC20(testToken).approve(address(OZ), amountIn);
        ozERC20.mint2{value: amts.amountInETH}(mintData, alice, true);

        vm.stopPrank();

        console.log('rETH_ETH - pre epoch: ', OZ.rETH_ETH());
        console.log('aUSDC bal in test - diamond - pre warp: ', IERC20Permit(aUsdcAddr).balanceOf(address(OZ)));

        /*** simulates time for staking rewards accrual ***/
        uint blockAccrual = mainBlockNumber + 7 days;
        console.log('blockAccrual - 20740190: ', blockAccrual);
        vm.warp(blockAccrual);

        console.log('');
        console.log('*** MOCK ***');
        console.log('');

        _mock_rETH_ETH_diamond();
        
        //---- mock BALANCER rETH<>WETH swap ----
        (
            IVault.SingleSwap memory singleSwap, 
            IVault.FundManagement memory funds
        ) = _constructBalancerSwap();

        uint rateRETHETH = 1154401364401861932;
        uint amountToSwapRETH = 946135001651163;
        uint swappedAmountWETH = rateRETHETH.mulDivDown(amountToSwapRETH, 1 ether);
        console.log('swappedAmountWETH in test: ', swappedAmountWETH);
        console.log('');

        console.log('weth bal oz pre mock: ', IERC20(wethAddr).balanceOf(address(OZ)));
        
        vm.mockCall(
            vaultBalancer,
            abi.encodeWithSelector(IVault.swap.selector, singleSwap, funds, 0, blockAccrual),
            abi.encode(swappedAmountWETH)
        );
        deal(wethAddr, address(OZ), swappedAmountWETH);

        //---- mock UNISWAP WETH<>USDC swap (not need for now since ETHUSD hasn't chan ged)----
        // ISwapRouter.ExactInputSingleParams memory params = _constructUniSwap(swappedAmountWETH);

        // vm.mockCall(
        //     swapRouterUni,
        //     abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, params),
        //     abi.encode()
        // );


        //--------------------------------------
        console.log('rETH_ETH - post epoch: ', OZ.rETH_ETH());
        /*******/

        bool success = OZ.executeRebaseSwap();
        console.log('success - true: ', success);

        // console.log('oz bal alice: ', ozERC20.balanceOf(alice));
    }
   
   //----------------


    function test_minting_approve_smallMint_balancer() public {
        _minting_approve_smallMint();
    }

    function test_minting_approve_bigMint_balancer() public {
        _minting_approve_bigMint();
    }

    function test_minting_eip2612_balancer() public { 
        _minting_eip2612();
    }   

    function test_ozToken_supply_balancer() public {
        _ozToken_supply();
    }

    function test_transfer_balancer() public {
        _transfer();
    }

    function test_redeeming_bigBalance_bigMint_bigRedeem_balancer() public {
        _redeeming_bigBalance_bigMint_bigRedeem();
    }

    function test_redeeming_bigBalance_smallMint_smallRedeem_balancer() public {
        _redeeming_bigBalance_smallMint_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_smallRedeem_balancer() public {
        _redeeming_bigBalance_bigMint_smallRedeem();
    }

    function test_redeeming_multipleBigBalances_bigMints_smallRedeem_balancer() public {
        _redeeming_multipleBigBalances_bigMints_smallRedeem();
    }

    function test_redeeming_bigBalance_bigMint_mediumRedeem_balancer() public {
        _redeeming_bigBalance_bigMint_mediumRedeem();
    }

    function test_redeeming_eip2612_balancer() public {
        _redeeming_eip2612();
    }

    function test_redeeming_multipleBigBalances_bigMint_mediumRedeem_balancer() public {
        _redeeming_multipleBigBalances_bigMint_mediumRedeem();
    }
}