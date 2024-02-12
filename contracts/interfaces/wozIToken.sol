// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC4626Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC20Upgradeable.sol";
import {ozIDiamond} from "./ozIDiamond.sol";

interface wozIToken is IERC20Upgradeable {

    function getWozAmount(uint ozAmount_) external view returns(uint);
    function getOzAmount(uint wozAmount_) external view returns(uint);
    function OZ() external view returns(ozIDiamond);

    function wrap(uint amountIn_, address receiver_) external returns(uint);
    function unwrap(uint wozAmountIn_, address receiver_, address owner_) external returns(uint);

    function asset() external view returns(address);
}


