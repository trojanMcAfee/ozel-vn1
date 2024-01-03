// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
// import {ozIToken} from "../../contracts/interfaces/ozIToken.sol";
import {IOZL} from "../../contracts/interfaces/IOZL.sol";

import "forge-std/console.sol";


contract OZLrewardsTest is TestMethods {


    function test_rewards() public {

        // ozIToken ozERC20 = ozIToken(OZ.createOzToken(
        //     testToken_, "Ozel-ERC20", "ozERC20"
        // ));

        IOZL OZL = IOZL(address(ozlProxy));

        console.log('---');
        uint x = OZL.balanceOf(address(ozlProxy));
        console.log('OZL own bal - pre: ', x);

        uint bal = OZL.balanceOf(address(OZ));
        console.log('oz bal: ', bal);

        x = OZL.balanceOf(address(ozlProxy));
        console.log('OZL own bal - post: ', x);

    }


}