// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {Test, console2} from "forge-std/Test.sol";
import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";


contract ozTokenFactoryTest is Test {
    ozTokenFactory public factory;

    address internal usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    function setUp() public {
        factory = new ozTokenFactory();
    }

    function test_createOzToken() public {
        // address x = factory.createOzToken(usdt, 100);
        // // console2.log("x: ", x);
        // console2_log("x: ", x);
    }

}