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
import {TradeAmounts} from "../../contracts/AppStorage.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {HelpersTests} from "./HelpersTests.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {

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

        //Action
        vm.prank(user_);
        uint shares = ozERC20_.mint(amounts, user_, v, r, s); 

        //Post-condit

        return shares;
    }

    function test_initialMintShares() public {
        //Pre-conditions
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20", IERC20Permit(testToken).decimals()
        ));

        uint rawAmount = 1000;
        uint shares = _mintOzTokens(ozERC20, rawAmount, alice, ALICE_PK);



        // (
        //     TradeAmounts memory amounts,
        //     uint8 v, bytes32 r, bytes32 s
        // ) = _createDataOffchain(ozERC20, rawAmount, ALICE_PK, alice);

        // //Action
        // vm.prank(alice);
        // uint shares = ozERC20.mint(amounts, alice, v, r, s); 

        //Post-conditions
        assertTrue(address(ozERC20) != address(0));
        assertTrue(shares == rawAmount * ( 10 ** ozERC20.decimals() ));
        // assertTrue(shares == ozERC20.balanceOf(alice));

        console.log('--------- ALICE ----------');
        console.log('');
        console.log('bal alice: ', ozERC20.balanceOf(alice));
        console.log('bal bob: ', ozERC20.balanceOf(bob));
        console.log('bal charlie: ', ozERC20.balanceOf(charlie));
        console.log('');
        console.log('shares alice: ', ozERC20.sharesOf(alice));
        console.log('shares bob: ', ozERC20.sharesOf(bob));
        console.log('shares charlie: ', ozERC20.sharesOf(charlie));
        console.log('');
        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('totalAssets: ', ozERC20.totalAssets());
        console.log('totalShares: ', ozERC20.totalShares());


        /**
         * Testing a 2nd user mint
         */
        console.log('--------- BOB ----------');

        // (
        //     amounts,
        //     v, r, s
        // ) = _createDataOffchain(ozERC20, 1000, BOB_PK, bob);

        // vm.prank(bob);
        // shares = ozERC20.mint(amounts, bob, v, r, s);

        shares = _mintOzTokens(ozERC20, 1000, bob, BOB_PK);

        console.log('');
        console.log('bal alice: ', ozERC20.balanceOf(alice));
        console.log('bal bob: ', ozERC20.balanceOf(bob));
        console.log('bal charlie: ', ozERC20.balanceOf(charlie));
        console.log('');
        console.log('shares alice: ', ozERC20.sharesOf(alice));
        console.log('shares bob: ', ozERC20.sharesOf(bob));
        console.log('shares charlie: ', ozERC20.sharesOf(charlie));
        console.log('');
        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('totalAssets: ', ozERC20.totalAssets());
        console.log('totalShares: ', ozERC20.totalShares());

        console.log('--------- CHARLIE ----------');
        // (
        //     amounts,
        //     v, r, s
        // ) = _createDataOffchain(ozERC20, 1000, CHARLIE_PK, charlie);

        // vm.prank(charlie);
        // shares = ozERC20.mint(amounts, charlie, v, r, s);

        shares = _mintOzTokens(ozERC20, 1000, charlie, CHARLIE_PK);

        console.log('');
        console.log('bal alice: ', ozERC20.balanceOf(alice));
        console.log('bal bob: ', ozERC20.balanceOf(bob));
        console.log('bal charlie: ', ozERC20.balanceOf(charlie));
        console.log('');
        console.log('shares alice: ', ozERC20.sharesOf(alice));
        console.log('shares bob: ', ozERC20.sharesOf(bob));
        console.log('shares charlie: ', ozERC20.sharesOf(charlie));
        console.log('');
        console.log('totalSupply: ', ozERC20.totalSupply());
        console.log('totalAssets: ', ozERC20.totalAssets());
        console.log('totalShares: ', ozERC20.totalShares());
    }








    function test_createOzToken2() internal {
        ozIToken ozERC20 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20", "ozERC20", IERC20Permit(testToken).decimals()
        ));
        assertTrue(address(ozERC20) != address(0));

        uint decimals = ozERC20.decimals();
        // console.log('decimals: ', decimals);
    }




    /** HELPERS ***/

    function _createDataOffchain( 
        ozIToken ozERC20_, 
        uint rawAmount_,
        uint SENDER_PK_,
        address sender_
    ) private returns(TradeAmounts memory amounts, uint8 v, bytes32 r, bytes32 s) { 
        uint amountIn = rawAmount_ * 10 ** ozERC20_.decimals();

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