// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TestMethods} from "../../../base/TestMethods.sol";


contract SharedConditions is TestMethods {

    ozIToken internal ozERC20;
    address internal testToken_internal;
    uint constant rawAmount = 100;


    modifier whenTheUnderlyingHas6Decimals() {
        (ozIToken a,) = _createOzTokens(usdcAddr, "1");
        ozERC20 = a;
        testToken_internal = ozERC20.asset();
        _;
    }

    modifier whenTheUnderlyingHas18Decimals() {
        (ozIToken a,) = _createOzTokens(daiAddr, "1");
        ozERC20 = a;
        testToken_internal = ozERC20.asset();
        _;
    }

    function _toggle(uint amount_, uint decimals_) internal pure returns(uint) {
        return decimals_ == 6 ? amount_ * 1e12 : amount_;
    }

    //--------

    function setUpOzToken(uint decimals_) internal returns(ozIToken, address) {
        address underlying = decimals_ == 6 ? usdcAddr : daiAddr; 
        (ozIToken a,) = _createOzTokens(underlying, "1"); //change "a" for ozERC20 if i end up removing the variable above
        return (a, underlying); 
    }

}