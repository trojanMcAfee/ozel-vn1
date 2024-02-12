// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {
    ERC4626Upgradeable,  
    ERC20Upgradeable,
    MathUpgradeable
} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/ERC4626Upgradeable.sol";
// import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/draft-EIP712Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {ozIToken} from "./interfaces/ozIToken.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/IERC20Upgradeable.sol";
import {AmountsIn} from "./AppStorage.sol";

import "forge-std/console.sol";


contract wozToken is ERC20Upgradeable, EIP712Upgradeable {

    using FixedPointMathLib for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _ozDiamond;
    ozIToken private _ozERC20;

    constructor() {
        _disableInitializers();
    }


    function initialize(
        string memory name_, 
        string memory symbol_,
        address asset_,
        address ozDiamond_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __EIP712_init(name_, "1");
        _ozDiamond = ozDiamond_;
        _ozERC20 = ozIToken(asset_);
    }

    function OZ() public view returns(ozIDiamond) {
        return ozIDiamond(_ozDiamond);
    }

    function asset() external view returns(address) {
        return address(_ozERC20);
    }


    function getWozAmount(uint ozAmount_) public view returns(uint) {
        return ozAmount_.mulDivDown(_ozERC20.totalShares() * 1e12, _ozERC20.totalSupply());
    }

    function getOzAmount(uint wozAmount_) public view returns(uint) {
        return wozAmount_.mulDivDown(_ozERC20.totalSupply(), _ozERC20.totalShares() * 1e12);
    }


    function unwrap(
        uint wozAmountIn_, 
        address receiver_, 
        address owner_
    ) public returns(uint ozTokensOut) { //put checks that amountIn_ can't be zero
        ozTokensOut = getOzAmount(wozAmountIn_);
        _burn(owner_, wozAmountIn_);
        IERC20Upgradeable(address(_ozERC20)).safeTransfer(receiver_, ozTokensOut);
    }

    function wrap(
        uint ozAmountIn_, 
        address owner_, 
        address receiver_
    ) public returns(uint wozAmountOut) {
        wozAmountOut = getWozAmount(ozAmountIn_);
        if (owner_ != address(this)) {
            IERC20Upgradeable(address(_ozERC20)).safeTransferFrom(owner_, address(this), ozAmountIn_);
        }
        _mint(receiver_, wozAmountOut);
    }

    
    function mintAndWrap(bytes memory data_, address owner_) external returns(uint wozAmountOut) {
        (bytes memory data, address originalReceiver) = _changeReceiver(data_);
        uint shares = _ozERC20.mint(data, owner_);
        uint ozAmountIn = _ozERC20.convertToAssets(shares);
        wozAmountOut = wrap(ozAmountIn, address(this), originalReceiver);
    }


    function _changeReceiver(bytes memory data_) private view returns(bytes memory, address) {
        (AmountsIn memory amts, address receiver) = 
            abi.decode(data_, (AmountsIn, address));

        return (abi.encode(amts, address(this)), receiver);
    }

    // function approve(address spender_, uint amount_) public override returns(bool) {
    //     address spender = spender_ == address(this) ? address(OZ()) : spender_;
    //     return super.approve(spender, amount_);
    // }


    //--------------

    function DOMAIN_SEPARATOR() external view returns (bytes32) {}
    function nonces(address owner) external view returns (uint256) {}
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {}

    //put a function that receives stable and mints wozToken in one go

}