// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {ozIToken} from "../../../../../contracts/interfaces/ozIToken.sol";
import {TestMethods} from "../../../base/TestMethods.sol";


contract SharedConditions is TestMethods {

    uint constant rawAmount = 100;
    address constant deadAddr = 0x000000000000000000000000000000000000dEaD;

    enum Revert {
        OWNER,
        AMOUNT_IN,
        RECEIVER,
        REENTRANT
    }

    function _setUpOzToken(uint decimals_) internal returns(ozIToken, address) {
        address underlying = decimals_ == 6 ? usdcAddr : daiAddr; 
        (ozIToken ozERC20,) = _createOzTokens(underlying, "1");
        return (ozERC20, underlying); 
    }

    function _setUpTwoOzTokens() internal returns(ozIToken, ozIToken) {
        (ozIToken ozUSDC,) = _createOzTokens(usdcAddr, "1");
        (ozIToken ozDAI,) = _createOzTokens(daiAddr, "1");
        return (ozUSDC, ozDAI);
    }

     function _toggle(uint amount_, uint decimals_) internal pure returns(uint) {
        return decimals_ == 6 ? amount_ * 1e12 : amount_;
    }

}