// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol"; //{ERC20Upgradeable} from
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import {ERC4626Upgradeable} from "./ERC4626Upgradeable.sol";
import {
    ERC4626Upgradeable, 
    IERC20MetadataUpgradeable, 
    ERC20Upgradeable,
    MathUpgradeable
} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/ERC4626Upgradeable.sol";

import "forge-std/console.sol";


error ozTokenInvalidMintReceiver(address account);


contract ozToken is ERC4626Upgradeable {
    
    using MathUpgradeable for uint;

    address private _ozDiamond;

    uint8 private _decimals;

    uint private constant _BASE = 1e18;
    uint private _totalShares;

    mapping(address user => uint256 shares) private _shares;

    event Transfer(address from, address to, uint amount);


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


    function getMult() public view returns(uint) {
        return ozIDiamond(_ozDiamond).getRewardMultiplier();
    }

    function decimals() public view override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns(uint8) {
        return _decimals;
    }

    function totalAssets() public view override returns(uint) {
        //do this (from ERC4626, not USDM)
    }

    function _convertToShares(uint assets_, MathUpgradeable.Rounding rounding_) internal view override returns(uint) {
        return assets_.mulDiv(_BASE, getMult(), rounding_);
    }

    function _convertToAssets(uint shares_, MathUpgradeable.Rounding rounding_) internal view override returns(uint) {
        return shares_.mulDiv(getMult(), _BASE, rounding_);
    }

    function totalShares() external view returns(uint) { //from USDM
        return _totalShares;
    }

    function totalSupply() external view override returns(uint) {
        return convertToAssets(_totalShares);
    }

    function sharesOf(address account_) public view returns(uint) {
        _shares[account_];
    }

    function balanceOf(address account_) external view override returns(uint) {
        return convertToAssets(sharesOf(account_));
    }

    function _mint(address to_, uint shares_) internal override { //check this against my ozToken version
        if (to_ == address(0)) revert ozTokenInvalidMintReceiver(to_);

        // uint256 shares = previewDeposit(amount_);
        _totalShares += shares_;

        unchecked {
            // Overflow not possible: shares + shares amount is at most totalShares + shares amount
            // which is checked above.
            _shares[to_] += shares_;
        }

        // emit Transfer(address(0), to_, shares_);
    }

    function _deposit(
        address caller_,
        address receiver_,
        uint256 assets_,
        uint256 shares_
    ) internal override {
        _mint(receiver_, shares_);
        emit Deposit(caller_, receiver_, assets_, shares_);
    }

    function deposit(uint assets_, address receiver_) public override returns(uint) {
        require(assets_ <= maxDeposit(receiver_), "ERC4626: deposit more than max");

        uint shares = previewDeposit(amount_);
        _deposit(_msgSender(), receiver_, assets_, shares);
    }

    function _burn(address account, uint256 amount) internal override {
        if (account == address(0)) { //working on this function ****
            revert USDMInvalidBurnSender(account);
        }

        _beforeTokenTransfer(account, address(0), amount);

        uint256 shares = convertToShares(amount);
        uint256 accountShares = sharesOf(account);

        if (accountShares < shares) {
            revert USDMInsufficientBurnBalance(account, accountShares, shares);
        }

        unchecked {
            _shares[account] = accountShares - shares;
            // Overflow not possible: amount <= accountShares <= totalShares.
            _totalShares -= shares;
        }

        _afterTokenTransfer(account, address(0), amount);
    }


}

