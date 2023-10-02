// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";
import {Setup} from "./Setup.sol";
import {ozIToken} from "../../interfaces/ozIToken.sol";

import "forge-std/console.sol";


contract ozTokenFactoryTest is Setup {
   

    function test_createOzToken() public {
        ozIToken ozUSDC = ozIToken(OZL.createOzToken(
            usdcAddr, "Ozel Tether", "ozUSDC", USDC.decimals()
        ));
        assertTrue(address(ozUSDC) != address(0));

        uint amount = 1000 * 10 ** ozUSDC.decimals();
        vm.startPrank(alice);

        USDC.approve(address(ozUSDC), amount);
        ozUSDC.mint(amount);
    }

    //testing createOzToken here and see if it works for minting 
    // a new PT with ozToken.
    //If it works, try minting YT and TT

}