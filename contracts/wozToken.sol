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

import "forge-std/console.sol";


contract wozToken is ERC20Upgradeable, EIP712Upgradeable {

    using FixedPointMathLib for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _ozDiamond;
    address private _ozToken;

    constructor() {
        _disableInitializers();
    }

    function getHello() public view {
        console.log(23);
        // console.log('ozDiamond: ', OZ());
    }


    function initialize(
        string memory name_, 
        string memory symbol_,
        address asset_,
        address ozDiamond_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        // __ERC4626_init(IERC20MetadataUpgradeable(asset_));
        __EIP712_init(name_, "1");
        _ozDiamond = ozDiamond_;
        _ozToken = asset_;
    }

    function OZ() public view returns(ozIDiamond) {
        return ozIDiamond(_ozDiamond);
    }


    // function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {
    //     return _ethAmount
    //         .mul(_getTotalShares())
    //         .div(_getTotalPooledEther());
    // }

    function getWozAmount(uint ozAmount_) public view returns(uint) {
        ozIToken ozERC20 = ozIToken(_ozToken);

        console.log('-- in getWozAmount --');
        console.log('ozAmount_: ', ozAmount_);
        console.log('ozERC20.totalAssets(): ', ozERC20.totalAssets());
        console.log('ozERC20.totalShares(): ', ozERC20.totalShares());
        console.log('ozERC20.totalSupply(): ', ozERC20.totalSupply());
        console.log('is other: ', ozAmount_.mulDivDown(ozERC20.totalShares() * 1e12, ozERC20.totalSupply()));
        console.log('-- in getWozAmount --');
        console.log('');

        return ozAmount_.mulDivDown(ozERC20.totalShares() * 1e12, ozERC20.totalSupply());
    }

    function getOzAmount(uint wozAmount_) public view returns(uint) {
        ozIToken ozERC20 = ozIToken(_ozToken);

        console.log('-- in getOzAmount --');
        console.log('wozAmount_: ', wozAmount_);
        console.log('ozERC20.totalAssets(): ', ozERC20.totalAssets());
        console.log('ozERC20.totalShares(): ', ozERC20.totalShares());
        console.log('ozERC20.totalSupply(): ', ozERC20.totalSupply());
        console.log('-- in getOzAmount --');
        console.log('');

        return wozAmount_.mulDivDown(ozERC20.totalSupply(), ozERC20.totalShares() * 1e12);
    }

    //getOzAmount() and getWozAmount() are the same so the final getOzAmount() is not 
    //captuing the tokens that got rebased^^^

    function unwrap(uint wozAmountIn_, address receiver_, address owner_) external {
        uint ozTokensOut = getOzAmount(wozAmountIn_);
        console.log('getOzAmount(wozAmountIn_) ^^^^^: ', ozTokensOut);

        _burn(owner_, wozAmountIn_);

        IERC20Upgradeable(_ozToken).transfer(receiver_, ozTokensOut);
    }

    function deposit2(uint amountIn_, address receiver_) external returns(uint) {
        // return getWozAmount(amountIn_);

        uint shares = getWozAmount(amountIn_);
        console.log('getWozAmount ^^^^: ', shares);

        IERC20Upgradeable(_ozToken).safeTransferFrom(msg.sender, address(this), amountIn_);


        _mint(receiver_, shares);
    }

    



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