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
    MathUpgradeable,
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {AppStorage, TradeAmounts} from "./AppStorage.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";

import "forge-std/console.sol";


error ozTokenInvalidMintReceiver(address account);

error ERC20InsufficientBalance(address sender, uint256 shares, uint256 sharesNeeded);
error ERC20InvalidSender(address sender);
error ERC20InvalidReceiver(address receiver);
error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
error ERC20InvalidApprover(address approver);
error ERC20InvalidSpender(address spender);
// ERC2612 Errors
error ERC2612ExpiredDeadline(uint256 deadline, uint256 blockTimestamp);
error ERC2612InvalidSignature(address owner, address spender);
// USDM Errors
error USDMInvalidMintReceiver(address receiver);
error USDMInvalidBurnSender(address sender);
error USDMInsufficientBurnBalance(address sender, uint256 shares, uint256 sharesNeeded);
error USDMInvalidRewardMultiplier(uint256 rewardMultiplier);
error USDMBlockedSender(address sender);
error USDMInvalidBlockedAccount(address account);
error USDMPausedTransfers();


contract ozToken is ERC4626Upgradeable {
    
    using MathUpgradeable for uint;

    AppStorage internal s;

    address private _ozDiamond;

    uint8 private _decimals;

    uint private constant _BASE = 1e18;
    uint private _totalShares;
    uint private _totalAssets;

    mapping(address user => uint256 shares) private _shares;

    event RewardMultiplier(uint256 indexed value);


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


    function _convertToShares(uint assets_, MathUpgradeable.Rounding rounding_) internal view override returns(uint) {
        // return assets_.mulDiv(_BASE, getMult(), rounding_);
        // console.log('assets in _convertToShares: ', assets_);
        // console.log('totalShares: ', totalShares());
        // console.log('totalAssets: ', totalAssets());

        return assets_.mulDiv(totalShares(), totalAssets(), rounding_);
    }

    function totalAssets() public view override returns(uint) {
        return _totalAssets;
    }

    // function _convertToAssets(uint shares_, MathUpgradeable.Rounding rounding_) internal view override returns(uint) {
    //     return shares_.mulDiv(getMult(), _BASE, rounding_);
    // }

    function totalShares() public view returns(uint) { //from USDM
        return _totalShares;
    }

    // function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns(uint) {
    //     return _convertToAssets(_totalShares, MathUpgradeable.Rounding.Down);
    // }

    /**
     * There are 2 totalSupply() funcs. This ^ and in ERC20Upgradeable.
     * The one in ERC20 goes along with _mint() there, so they go hand in hand.
     * Do more test and see which ones is the correct one. 
     * I think it's ERC20
     */

    function sharesOf(address account_) public view returns(uint) {
        return _shares[account_];
    }

    function balanceOf(address account_) public view override(ERC20Upgradeable, IERC20Upgradeable) returns(uint) {
        return convertToAssets(sharesOf(account_));
    }


    function mint( 
        TradeAmounts memory amounts_,
        address receiver_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns(uint) {
        address token = asset();

        IERC20Permit(token).permit(
            msg.sender,
            _ozDiamond,
            amounts_.amountIn,
            block.timestamp,
            v_, r_, s_
        );

        ozIDiamond(_ozDiamond).useUnderlying(token, msg.sender, amounts_); 

        uint shares = deposit(amounts_.amountIn, receiver_);

        _totalAssets += amounts_.amountIn;

        return shares;

        // ozIDiamond(_ozDiamond).useUnderlying(token, msg.sender, receiver_, amounts_); 
    }

    function _deposit( //test mint/deposit ****
        address caller_,
        address receiver_,
        uint256 assets_,
        uint256 shares_
    ) internal override { 
        _totalShares += shares_;

        unchecked {
            // Overflow not possible: shares + shares amount is at most totalShares + shares amount
            // which is checked above.
            _shares[receiver_] += shares_;
        }

        // console.log('*** _deposit ***');
        // uint assets = convertToAssets(shares_);
        // console.log('assets ^^^ - should not 0: ', assets);
        // console.log('assets_: ', assets_);
        // console.log('sharesOf ****: ', sharesOf(receiver_));
        _mint(receiver_, assets_);
        // console.log('totalSupply: ', totalSupply());
        
        emit Deposit(caller_, receiver_, assets_, shares_);
    }


    function deposit(uint assets_, address receiver_) public override returns(uint) {
        require(assets_ <= maxDeposit(receiver_), "ERC4626: deposit more than max");

        uint shares = totalSupply() == 0 ? assets_ : previewDeposit(assets_);

        _deposit(_msgSender(), receiver_, assets_, shares);

        return shares;
    }


    function _burn(address account, uint256 amount) internal override {
        if (account == address(0)) revert ozTokenInvalidMintReceiver(account); //change the error here
    
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

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        //do this function comparing with _withdraw()
    }

    function _convertToAssets(uint256 shares_, MathUpgradeable.Rounding rounding_) internal view override returns (uint256 assets) {
        // console.log('------------------');
        // console.log('shares: ', shares_);
        // console.log('totalAssets: ', totalAssets());
        // console.log('totalShares: ', totalShares());
        // console.log('underlying val: ', ozIDiamond(_ozDiamond).getUnderlyingValue());
        // console.log('------------------');
        // return shares_.mulDiv(totalAssets(), totalShares(), rounding_);


        return (shares_ * 1e12).mulDiv(ozIDiamond(_ozDiamond).getUnderlyingValue() / totalShares(), 1e21, rounding_);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(0)) {
            revert ERC20InvalidSender(from);
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(to);
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 shares = convertToShares(amount); //put there one of the previews...
        uint256 fromShares = _shares[from];

        if (fromShares < shares) {
            revert ERC20InsufficientBalance(from, fromShares, shares);
        }

        unchecked {
            _shares[from] = fromShares - shares;
            // Overflow not possible: the sum of all shares is capped by totalShares, and the sum is preserved by
            // decrementing then incrementing.
            _shares[to] += shares;
        }

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * Multiplier stuff
     */
     function _setRewardMultiplier(uint256 _rewardMultiplier) private {
        if (_rewardMultiplier < _BASE) {
            revert USDMInvalidRewardMultiplier(_rewardMultiplier);
        }

        s.rewardMultiplier = _rewardMultiplier;

        emit RewardMultiplier(s.rewardMultiplier);
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) external { //protect this funciton
        _setRewardMultiplier(_rewardMultiplier);
    }

    function addRewardMultiplier(uint256 _rewardMultiplierIncrement) external {
        if (_rewardMultiplierIncrement == 0) {
            revert USDMInvalidRewardMultiplier(_rewardMultiplierIncrement);
        }

        _setRewardMultiplier(s.rewardMultiplier + _rewardMultiplierIncrement);
    }


}

