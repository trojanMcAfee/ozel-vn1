// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";

import "forge-std/console.sol";


contract OZLtokenTest is TestMethods {


    function test_token() public {
        // _minting_approve_smallMint();

        console.log('ozDiamond in test: ', address(OZ));

        IOZL ozl = IOZL(OZ.getOZL());
        ozl.getRewards();
    }


}