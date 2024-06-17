// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {TestMethods} from "../base/TestMethods.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {Type} from "../base/AppStorageTests.sol";
import {HelpersLib} from "../utils/HelpersLib.sol";
import {AmountsIn} from "../../../contracts/AppStorage.sol";
import {OZError21} from "../../../contracts/Errors.sol";
import {Asset} from "../../../contracts/AppStorage.sol";



contract OtherTests is TestMethods {

    //Tests that the totalUnderlying is calculated accurately.
    function test_totalUnderlying() public {
        //Pre-condition + Action
        _minting_approve_smallMint();

        //Post-conditions
        uint totalUSD = OZ.totalUnderlying(Asset.USD);
        uint ozDiamondRethBalance = IERC20Permit(rEthAddr).balanceOf(address(OZ));

        assertTrue(_checkPercentageDiff(totalUSD, ((ozDiamondRethBalance * OZ.rETH_USD()) / 1 ether^2), 1));
    }

    /**
     * An inflation attack wouldn't be possible since it'd be filtered out 
     * by Balancer when trying to do one of the internal swaps
     */
    function test_inflation_attack() public { //<--- once all it's ready, refactor this test and run it again (SC programmer YT)
        /**
         * Pre-conditions
         */
        _dealUnderlying(Quantity.BIG, false);
        address attacker = alice;
        address victim = charlie;
        uint amountIn = 1;

        (ozIToken ozERC20,) = _createOzTokens(testToken, "1");
        
        (bytes memory data) = _createDataOffchain(
            ozERC20, amountIn, ALICE_PK, attacker, testToken, Type.IN
        );

        (uint[] memory minAmountsOut,,,) = HelpersLib.extract(data);

        vm.startPrank(attacker);

        IERC20Permit(testToken).approve(address(ozDiamond), amountIn);

        AmountsIn memory amounts = AmountsIn(
            amountIn,
            1,
            2
        );

        bytes memory mintData = abi.encode(amounts, attacker);

        //The flow of the attack would revert here before the attack even happens.
        vm.expectRevert(
            abi.encodeWithSelector(OZError21.selector, 'BAL#510')
        );
        ozERC20.mint(mintData, attacker); 

        /**
         * Action (attack)
         */
        amountIn = testToken == daiAddr ? 10_000e18 - 1 : 10_000e6 - 1;

        _createAndMintOzTokens(
            address(ozERC20), amountIn, attacker, ALICE_PK, false, true, Type.IN
        );

        /**
         * Post-conditions
         */
        amountIn = testToken == daiAddr ? 19999e18 - 1 : 19999e6 - 1;

        _createAndMintOzTokens(
            address(ozERC20), amountIn, charlie, CHARLIE_PK, false, true, Type.IN
        );

        uint balVictim = ozERC20.balanceOf(victim);
        assertTrue(balVictim > 1);
    }


    function test_ozTokenRegistry() public {
        //Action
        _minting_approve_smallMint();

        //Post-conditions
        assertTrue(OZ.getOzTokenRegistry().length == 1);
        assertTrue(OZ.isInRegistry(testToken));
    }

}