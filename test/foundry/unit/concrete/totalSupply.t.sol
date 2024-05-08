// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {TestMethods} from "../../base/TestMethods.sol";
import {ozIToken} from "../../../../contracts/interfaces/ozIToken.sol";


contract totalSupply_Unit_Concrete_Test is TestMethods {
    
    ozIToken ozERC20;
    string constant version = "1";

    modifier whenTheUnderlyingHas6Decimals() {
        (ozIToken a,) = _createOzTokens(usdcAddr, version);
        ozERC20 = a;
        _;
    }

    /**
     * Action: it should return 0.
     */
    function test_GivenTotalSharesEqual0_6() external whenTheUnderlyingHas6Decimals {
        //Pre-condition
        assertEq(ozERC20.totalShares(), 0);

        //Post-condition
        assertEq(ozERC20.totalSupply(), 0);
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
        //Pre-condition
        assertEq(ozERC20.totalShares(), 0);

        //Post-condition
        assertEq(ozERC20.totalSupply(), 0);
    }

    function test_GivenTotalSharesIsNotEqualTo0_18() external whenTheUnderlyingHas18Decimals {
        // it should return the sum of all users' balances.
    }
}
