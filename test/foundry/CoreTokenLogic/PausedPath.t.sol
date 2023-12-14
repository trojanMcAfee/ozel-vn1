// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {TestMethods} from "../TestMethods.sol";
import {IPool, IQueries} from "../../../contracts/interfaces/IBalancer.sol";

import "forge-std/console.sol";


contract PausedPathTest is TestMethods {

    modifier pauseBalancerPool() {
        vm.mockCall(
            rEthWethPoolBalancer,
            abi.encodeWithSignature('getPausedState()'),
            abi.encode(true, uint(0), uint(0))
        );
        _;
        vm.clearMockedCalls();
    }


    function test_minting_approve_smallMint_paused() public pauseBalancerPool {
        _minting_approve_smallMint();
    }



}