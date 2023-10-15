// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


// import "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol"; //{ERC20Upgradeable} from
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import {ERC4626Upgradeable} from "./ERC4626Upgradeable.sol";
import {
    ERC4626Upgradeable, 
    IERC20MetadataUpgradeable, 
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/ERC4626Upgradeable.sol";


contract ozToken is ERC4626Upgradeable {

    address private _ozDiamond;

    uint8 private _decimals;

    // constructor(
    //     address underlying_,
    //     address diamond_,
    //     string memory name_,
    //     string memory symbol_
    // ) ERC4626(IERC20(underlying_)) ERC20(name_, symbol_) {
    //     _ozDiamond = diamond_;
    // }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address underlying_,
        address diamond_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20MetadataUpgradeable(underlying_));
        _ozDiamond = diamond_;
        _decimals = decimals_;
    }


    function decimals() public view override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns(uint8) {
        return _decimals;
    }


}

