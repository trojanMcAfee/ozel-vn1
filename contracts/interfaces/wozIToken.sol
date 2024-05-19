// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import {IERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC4626Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/interfaces/IERC20Upgradeable.sol";
import {ozIDiamond} from "./ozIDiamond.sol";
// import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {IERC20Permit} from "./IERC20Permit.sol";


interface wozIToken is IERC20Permit {

    function getWozAmount(uint ozAmount_) external view returns(uint);
    function getOzAmount(uint wozAmount_) external view returns(uint);
    function OZ() external view returns(ozIDiamond);

    function wrap(uint amountIn_, address owner_, address receiver_) external returns(uint);
    function unwrap(uint wozAmountIn_, address receiver_, address owner_) external returns(uint);

    function asset() external view returns(address);

    function mintAndWrap(bytes memory data_, address owner_) external returns(uint);
}


