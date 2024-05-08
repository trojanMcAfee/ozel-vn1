// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {TotalSupply_Core} from "./totalSupply_core.sol";

import {console} from "forge-std/console.sol";

contract TotalSupply_Unit_Concrete_Test is TotalSupply_Core {
    
    ozIToken ozERC20;
    string constant version = "1";

    modifier whenTheUnderlyingHas6Decimals() {
        (ozIToken a,) = _createOzTokens(usdcAddr, "2");
        ozERC20 = a;
        _;
    }

    /**
     * Action: it should return 0.
     */
    function test_GivenTotalSharesEqual0_6() external whenTheUnderlyingHas6Decimals {
        it_should_return_0(ozERC20, 6);
    }

    function test_GivenTotalSharesIsNotEqualTo0_6() external whenTheUnderlyingHas6Decimals {
        // it should return the sum of all users' balances.
    }

    modifier whenTheUnderlyingHas18Decimals() {
        (ozIToken a,) = _createOzTokens(daiAddr, version);
        ozERC20 = a;
        _;
    }

    /**
     * Action: it should return 0.
     */
    function test_GivenTotalSharesEqual0_18() external whenTheUnderlyingHas18Decimals {
        it_should_return_0(ozERC20, 18);
    }

    function test_GivenTotalSharesIsNotEqualTo0_18() external whenTheUnderlyingHas18Decimals {
        // it should return the sum of all users' balances.
    }
}
