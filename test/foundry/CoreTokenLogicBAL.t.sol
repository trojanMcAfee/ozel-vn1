// // SPDX-License-Identifier: GPL-2.0-or-later
// pragma solidity 0.8.21;



// contract CoreTokenLogicBALtest {


//     function test_minting_approve_smallMint_balancer() internal {
//         //Pre-condition
//         (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);
//         uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();

//         //Action
//         (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
//             testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
//         );

//         //Post-conditions
//         uint balAlice = ozERC20.balanceOf(alice);

//         assertTrue(address(ozERC20) != address(0));
//         assertTrue(sharesAlice == rawAmount * SHARES_DECIMALS_OFFSET);
//         assertTrue(balAlice > 99 * 1 ether && balAlice < rawAmount * 1 ether);
//     }

//     function test_minting_approve_bigMint_balancer() public {
//         //Pre-condition
//         (uint rawAmount,,) = _dealUnderlying(Quantity.BIG);
//         uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
//         _changeSlippage(9900);

//         //Action
//         (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
//             testToken, amountIn, alice, ALICE_PK, true, false, Type.IN
//         );

//         //Post-conditions
//         uint balAlice = ozERC20.balanceOf(alice);

//         assertTrue(address(ozERC20) != address(0));
//         assertTrue(sharesAlice == rawAmount * SHARES_DECIMALS_OFFSET);
//         assertTrue(balAlice > 977_000 * 1 ether && balAlice < rawAmount * 1 ether);
//     }

//     function test_minting_eip2612_balancer() public { 
//         /**
//          * Pre-conditions + Actions (creating of ozTokens)
//          */
//         bytes32 oldSlot0data = vm.load(
//             IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, fee), 
//             bytes32(0)
//         );
//         (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();

//         (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL);

//         /**
//          * Actions
//          */
//         uint amountIn = rawAmount * 10 ** IERC20Permit(testToken).decimals();
//         (ozIToken ozERC20, uint sharesAlice) = _createAndMintOzTokens(
//             testToken, amountIn, alice, ALICE_PK, true, true, Type.IN
//         );
//         _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

//         amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
//         (, uint sharesBob) = _createAndMintOzTokens(
//             address(ozERC20), amountIn, bob, BOB_PK, false, true, Type.IN
//         );
//         _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);

//         amountIn = (rawAmount / 4) * 10 ** IERC20Permit(testToken).decimals();
//         (, uint sharesCharlie) = _createAndMintOzTokens(
//             address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
//         );
//         _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);


//         //Post-conditions
//         assertTrue(address(ozERC20) != address(0));
//         assertTrue(sharesAlice == rawAmount * SHARES_DECIMALS_OFFSET);
//         assertTrue(sharesAlice / 2 == sharesBob);
//         assertTrue(sharesAlice / 4 == sharesCharlie);
//         assertTrue(sharesBob == sharesCharlie * 2);
//         assertTrue(sharesBob / 2 == sharesCharlie);

//         uint balanceAlice = ozERC20.balanceOf(alice);
//         uint balanceBob = ozERC20.balanceOf(bob);
//         uint balanceCharlie = ozERC20.balanceOf(charlie);
    
//         assertTrue(balanceAlice / 2 == balanceBob);
//         assertTrue(balanceAlice / 4 == balanceCharlie);
//         assertTrue(balanceBob == balanceCharlie * 2);
//         assertTrue(ozERC20.totalSupply() == balanceAlice + balanceCharlie + balanceBob);
//         assertTrue(ozERC20.totalAssets() == (rawAmount + rawAmount / 2 + rawAmount / 4) * 1e6);
//         assertTrue(ozERC20.totalShares() == sharesAlice + sharesBob + sharesCharlie);
//     }   

//     function test_ozToken_supply_balancer() public {}

//     function test_transfer_balancer() public {}

//     function test_redeeming_bigBalance_bigMint_bigRedeem_balancer() public {}

//     function test_redeeming_bigBalance_smallMint_smallRedeem_balancer() public {}

//     function test_redeeming_bigBalance_bigMint_smallRedeem_balancer() public {}

//     function test_redeeming_multipleBigBalances_bigMints_smallRedeem_balancer() public {}

//     function test_redeeming_bigBalance_bigMint_mediumRedeem_balancer() public {}

//     function test_redeeming_eip2612_balancer() public {}

//     function test_redeeming_multipleBigBalances_bigMint_mediumRedeem_balancer() public {}


// }