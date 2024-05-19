// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {Helpers} from "./../../../../contracts/libraries/Helpers.sol";


contract MockRocketVault {

    using Helpers for *;
    
    bool flag;

    function balanceOf(string memory pool_) external view returns(uint) {
        return !flag ? pool_.compareStrings('rocketDepositPool') ? 1 : 0 : 0;
    }
}


contract MockReentrantRocketVault {

    function balanceOf(string memory pool_) external {
        
    }

}   