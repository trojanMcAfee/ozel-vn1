// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TestMethods} from "../../../base/TestMethods.sol";


contract SharedConditions is TestMethods {

    ozIToken internal ozERC20;

    modifier whenTheUnderlyingHas6Decimals() {
        (ozIToken a,) = _createOzTokens(usdcAddr, "1");
        ozERC20 = a;
        _;
    }

    modifier whenTheUnderlyingHas18Decimals() {
        (ozIToken a,) = _createOzTokens(daiAddr, "1");
        ozERC20 = a;
        _;
    }

}