// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {Mint_Core} from "./Mint_Core.sol";


contract Mint_Unit_Concrete_test is Mint_Core {
    

    /*//////////////////////////////////////////////////////////////
                                6 DECIMALS
    //////////////////////////////////////////////////////////////*/    

    function test_WhenAmountInIsZero_6() external whenTheUnderlyingHas6Decimals {
        it_should_revert(6);
    }

    function test_WhenUnderlyingIsZero_6() external whenTheUnderlyingHas6Decimals {
        // it should revert.
    }

    function test_WhenUnderlyingIsAnOzToken_6() external whenTheUnderlyingHas6Decimals {
        // it should mint.
    }

    function test_RevertWhen_UnderlyingIsNotAnOzToken_6() external whenTheUnderlyingHas6Decimals {
        // it should revert
    }

    /*//////////////////////////////////////////////////////////////
                                18 DECIMALS
    //////////////////////////////////////////////////////////////*/    

    function test_WhenAmountInIsZero_18() external whenTheUnderlyingHas18Decimals {
        // it should revert.
    }

    function test_WhenUnderlyingIsZero_18() external whenTheUnderlyingHas18Decimals {
        // it should revert.
    }

    function test_WhenUnderlyingIsAnOzToken_18() external whenTheUnderlyingHas18Decimals {
        // it should mint.
    }

    function test_RevertWhen_UnderlyingIsNotAnOzToken_18() external whenTheUnderlyingHas18Decimals {
        // it should revert
    }
}
