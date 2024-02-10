// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC4626Upgradeable.sol";


interface wozIToken is IERC4626Upgradeable {
    function getHello() external view;
    //------


    function deposit2(uint amountIn_) external returns(uint);

}


