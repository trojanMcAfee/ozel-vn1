// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
import {TestMethods} from "./TestMethods.sol";

import "forge-std/console.sol";


contract MultipleTokensTest is TestMethods {

    
    function test_x() internal {
        bytes32 oldSlot0data = vm.load(
            IUniswapV3Factory(uniFactory).getPool(wethAddr, testToken, uniPoolFee), 
            bytes32(0)
        );
        (bytes32 oldSharedCash, bytes32 cashSlot) = _getSharedCashBalancer();
        
        //--------
        ozIToken ozERC20_1 = ozIToken(OZ.createOzToken(
            testToken, "Ozel-ERC20-1", "ozERC20_1"
        ));

        ozIToken ozERC20_2 = ozIToken(OZ.createOzToken(
            secondTestToken, "Ozel-ERC20-2", "ozERC20_2"
        ));


        (uint rawAmount,,) = _dealUnderlying(Quantity.SMALL, true);
        uint amountIn = (rawAmount / 2) * 10 ** IERC20Permit(testToken).decimals();
        _changeSlippage(uint16(9900));

        //----------
        _startCampaign();

        _mintOzTokens(ozERC20_1, alice, testToken, amountIn);
        // _resetPoolBalances(oldSlot0data, oldSharedCash, cashSlot);
        _mintOzTokens(ozERC20_2, alice, secondTestToken, amountIn);

        uint bal1 = ozERC20_1.balanceOf(alice);
        uint bal2 = ozERC20_2.balanceOf(alice);

        console.log('bal1: ', bal1);
        console.log('bal2: ', bal2);

    }




}