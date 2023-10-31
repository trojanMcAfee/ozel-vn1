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
import {AppStorage, TradeAmounts, TradeAmountsOut} from "./AppStorage.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/draft-EIP712Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/CountersUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/ECDSAUpgradeable.sol";

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


contract ozToken is ERC4626Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using MathUpgradeable for uint;

    AppStorage internal s;

    address private _ozDiamond;

    uint private constant _BASE = 1e18;
    uint private _totalShares;
    uint private _totalAssets;

    mapping(address user => uint256 shares) private _shares;
    mapping(address => CountersUpgradeable.Counter) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // event RewardMultiplier(uint256 indexed value);


    constructor() {
        _disableInitializers();
    }

    function initialize(
        address underlying_,
        address diamond_,
        string memory name_,
        string memory symbol_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20MetadataUpgradeable(underlying_));
        __EIP712_init(name_, "1");
        _ozDiamond = diamond_;
    }


    //bugg here ***
    function _convertToShares(uint assets_, MathUpgradeable.Rounding rounding_) internal view override returns(uint) {
        return assets_.mulDiv(totalShares(), ozIDiamond(_ozDiamond).getUnderlyingValue(), rounding_);
    }

    function totalAssets() public view override returns(uint) {
        return _totalAssets;
    }

    function totalShares() public view returns(uint) { //from USDM
        return _totalShares;
    }

    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns(uint) {
        return _totalShares == 0 ? 0 : _convertToAssets(_totalShares, MathUpgradeable.Rounding.Down);
    }

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
    ) external returns(uint) { //check if this return (shares) is necessary
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
    }

    function _convertToSharesUnderlying(uint assets_, MathUpgradeable.Rounding rounding_) private view returns(uint) {
        return assets_.mulDiv(totalShares(), totalAssets(), rounding_);
    }

    function previewDeposit(uint assets_) public view override returns(uint) {
        return _convertToSharesUnderlying(assets_, MathUpgradeable.Rounding.Down);
    }


    function _deposit( 
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

        _mint(receiver_, assets_);
        
        emit Deposit(caller_, receiver_, assets_, shares_);
    }

    //this previewDeposit (calls _convertToShares) uses assets_ as the incoming USDC in minting.
    //while _convertToSahres on the previewWithdraw of the test uses amountIn as the ozERC20 ball (the correct appraoch)
    //possible solution --> add a new previewDeposit that gets called only when depositing USDC

    function deposit(uint assets_, address receiver_) public override returns(uint) {
        require(assets_ <= maxDeposit(receiver_), "ERC4626: deposit more than max");

        console.log('totalShares in depo: ', totalShares());
        uint shares = totalShares() == 0 ? assets_ : previewDeposit(assets_);

        _deposit(_msgSender(), receiver_, assets_, shares);

        return shares;
    }


    function _burn(address account, uint256 shares) internal override {
        if (account == address(0)) revert ozTokenInvalidMintReceiver(account); //change the error here
    
        // uint256 shares = convertToShares(amount);
        uint256 accountShares = sharesOf(account);
        uint assets = convertToAssets(shares);
    
        if (accountShares < shares) {
            revert USDMInsufficientBurnBalance(account, accountShares, shares);
        }

        unchecked {
            _shares[account] = accountShares - shares;
            // Overflow not possible: amount <= accountShares <= totalShares.
            _totalShares -= shares;
            _totalAssets -= assets;
        }

        // _afterTokenTransfer(account, address(0), amount);
    }
    
    //underlying is BPT ***
    function convertToUnderlying(uint shares_) public view returns(uint amountUnderlying) {
        amountUnderlying = (shares_ * ozIDiamond(_ozDiamond).totalUnderlying()) / totalShares();
    }

    // struct TradeAmountsOut {
    //     uint ozAmountIn;
    //     uint minWethOut;
    //     uint bptAmountIn;
    // }

    function burn2(uint amount, address receiver) public {
        // this.transferFrom(msg.sender, receiver, amount);
        // this.transfer(receiver, amount);

        (bool success,) = address(this).delegatecall(
            abi.encodeWithSelector(
                this.transfer.selector,
                receiver, amount
            )
        );
        require(success, "Fff");
    }



    function burn(
        TradeAmountsOut memory amts_,
        address receiver_
    ) public {
        // address(this).safeTransferFrom(msg.sender, _ozDiamond);

        //remove from ozIToken.sol also

    }

    function burn(
        TradeAmountsOut memory amts_,
        address receiver_,
        uint8 v_, bytes32 r_, bytes32 s_
    ) public returns(uint) {

        //Move the ozToken from sender to _ozDiamond
        IERC20Permit(address(this)).permit(
            msg.sender,
            _ozDiamond,
            amts_.ozAmountIn,
            block.timestamp,
            v_, r_, s_
        );

        ozIDiamond(_ozDiamond).useOzTokens(
            amts_,
            address(this),
            msg.sender,
            receiver_
        );

        // ozIDiamond(_ozDiamond).uzeOzTokens(amts_, address(this), msg.sender, receiver_);
        // bytes4 x = ozIDiamond(_ozDiamond).uzeOzTokens.selector;
        // console.logBytes4(x);
        // console.log('selector ^^^');
        // revert('here');

        //Gets the amount of shares per ozTokens transferred
        uint shares = withdraw(amts_.ozAmountIn, receiver_, msg.sender);

        //Converts from shares to BPT
        // amts_.bptAmountIn = convertToUnderlying(shares);

        // /**
        //  * - Redeems BPT for rETH
        //  * - Swaps rETH for USDC
        //  */
        // ozIDiamond(_ozDiamond).useOzTokens(
        //     amts_,
        //     address(this),
        //     msg.sender,
        //     receiver_
        // );

        uint assets = IERC20Permit(asset()).balanceOf(address(this));
        _withdraw(_msgSender(), receiver_, msg.sender, assets, shares);

        //Transfers USDC to receiver
        // uint asset = asset();
        // asset.safeTransferFrom(
        //     address(this), 
        //     receiver_, 
        //     IERC20Permit(asset).balanceOf(address(this))
        // );

        //Updates totalSupply, totalAssets, and totalShares

       
        return 1;

    }


    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) internal override {
        if (from == address(0)) {
            revert ERC20InvalidSender(from);
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(to);
        }

        uint256 shares = convertToShares(amount);
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
    }


    // function _withdraw(
    //     address caller,
    //     address receiver,
    //     address owner,
    //     uint256 assets,
    //     uint256 shares
    // ) internal override {
    //     //do this function comparing with _withdraw()
    // } 

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public view override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);

        // _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }


    function _convertToAssets(uint256 shares_, MathUpgradeable.Rounding rounding_) internal view override returns (uint256 assets) {
        return shares_.mulDiv((ozIDiamond(_ozDiamond).getUnderlyingValue() / totalShares()), 1, rounding_);
    }

    //----------------------

    /**
     * @notice Returns the EIP-712 DOMAIN_SEPARATOR.
     * @return A bytes32 value representing the EIP-712 DOMAIN_SEPARATOR.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Returns the current nonce for the given owner address.
     * @param owner The address whose nonce is to be retrieved.
     * @return The current nonce as a uint256 value.
     */
    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Private function that increments and returns the current nonce for a given owner address.
     * @param owner The address whose nonce is to be incremented.
     */
    function _useNonce(address owner) private returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();

        nonce.increment();
    }

    /**
     * @notice Allows an owner to approve a spender with a one-time signature, bypassing the need for a transaction.
     * @dev Uses the EIP-2612 standard.
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @param value The amount of tokens to be approved.
     * @param deadline The expiration time of the signature, specified as a Unix timestamp.
     * @param v The recovery byte of the signature.
     * @param r The first 32 bytes of the signature.
     * @param s_ The second 32 bytes of the signature.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) external {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredDeadline(deadline, block.timestamp);
        }

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hash, v, r, s_);

        if (signer != owner) {
            revert ERC2612InvalidSignature(owner, spender);
        }

        _approve(owner, spender, value);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;


    // function nonces(address owner) external view returns (uint256) {
    //     // return _nonces[owner].current();
    // }

    // enum Asset {
    //     USD,
    //     UNDERLYING
    // }

    // function totalUnderlying(Asset type_) public view returns(uint) {
    //     uint subTotal = IERC20Permit(s.rEthWethPoolBalancer).balanceOf(_ozDiamond);

    //     if (type_ == UNDERLYING) {
    //         return IERC20Permit(s.rEthWethPoolBalancer).balanceOf(_ozDiamond);
    //     } else if (type_ == USD) {

    //     }
    // }


    // function _transfer(address from, address to, uint256 amount) internal override {
    //     if (from == address(0)) {
    //         revert ERC20InvalidSender(from);
    //     }
    //     if (to == address(0)) {
    //         revert ERC20InvalidReceiver(to);
    //     }

    //     _beforeTokenTransfer(from, to, amount);

    //     uint256 shares = convertToShares(amount); //put there one of the previews...
    //     uint256 fromShares = _shares[from];

    //     if (fromShares < shares) {
    //         revert ERC20InsufficientBalance(from, fromShares, shares);
    //     }

    //     unchecked {
    //         _shares[from] = fromShares - shares;
    //         // Overflow not possible: the sum of all shares is capped by totalShares, and the sum is preserved by
    //         // decrementing then incrementing.
    //         _shares[to] += shares;
    //     }

    //     _afterTokenTransfer(from, to, amount);
    // }



}

