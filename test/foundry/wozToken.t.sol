// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "./TestMethods.sol";
import {wozIToken} from "../../contracts/interfaces/wozIToken.sol";
import {NewToken} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract wozTokenTest is TestMethods {

    function test_x() public {
        // NewToken memory ozToken = NewToken("Ozel-ERC20", "ozERC20");
        // NewToken memory wozToken = NewToken("Wrapped Ozel-ERC20", "wozERC20");

        // (,address newWozToken) = OZ.(testToken, ozToken, wozToken);

        (, wozIToken wozERC20) = _createOzTokens(testToken, "1");
        wozERC20.getHello();


    }


}