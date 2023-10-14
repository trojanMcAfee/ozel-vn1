// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


// import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";
import {ERC4626, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";


contract ozToken is ERC4626 {

    address private immutable _ozDiamond;

    constructor(
        address underlying_,
        address diamond_,
        string memory name_,
        string memory symbol_
    ) ERC4626(IERC20(underlying_)) ERC20(name_, symbol_) {
        _ozDiamond = diamond_;
    }


}

