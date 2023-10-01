// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {console2} from "forge-std/Test.sol";
import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";


contract ozTokenFactoryTest is Setup {
   

    function test_createOzToken() public {
        address x = ozl.createOzToken(usdt, 100);
        console2.log("x: ", x);
    }

    //testing createOzToken here and see if it works for minting 
    // a new PT with ozToken.
    //If it works, try minting YT and TT

}