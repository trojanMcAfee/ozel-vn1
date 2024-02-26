// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {
    ERC4626Upgradeable,  
    ERC20Upgradeable,
    MathUpgradeable,
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {AmountsIn, AmountsOut, Asset} from "./AppStorage.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/draft-EIP712Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/CountersUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/ECDSAUpgradeable.sol";

import {AmountsIn} from "./AppStorage.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";
import {Helpers, TotalType} from "./libraries/Helpers.sol";
import {Modifiers} from "./Modifiers.sol";
import "./Errors.sol";

import "forge-std/console.sol";



/**
 * Like in Lido's stETH, the Transfer event is only emitted in _transfer, and not in rebases
 * Check the definition of Transfer event here: https://eips.ethereum.org/EIPS/eip-20
 * It says should, not must: A token contract which creates new tokens SHOULD trigger
 * .
 * _convertToShares is rounded up, against ERC4626 which says to round down.
 * doesn't have a deposit() function
 */
contract ozToken is Modifiers, IERC20MetadataUpgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    using FixedPointMathLib for uint;
    using Helpers for uint;
    using Helpers for bytes32;

    address private _ozDiamond;
    address private _underlying;
    
    bytes32 private _assetsAndShares;

    mapping(address user => uint256 shares) private _shares;
    mapping(address => CountersUpgradeable.Counter) private _nonces;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Token name
    string private _name;
    // Token Symbol
    string private _symbol;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint public FORMAT_DECIMALS;

    uint constant MASK = 2 ** (128) - 1;
    
    mapping(address user => uint assets) private _assets;


    constructor() {
        _disableInitializers();
    }

    function initialize(
        address underlying_,
        address diamond_,
        string memory name_,
        string memory symbol_
    ) external initializer {
        _name = name_;
        _symbol = symbol_;
        _ozDiamond = diamond_;
        _underlying = underlying_;
        __EIP712_init(name_, "1");
        FORMAT_DECIMALS = IERC20Permit(underlying_).decimals() == 18 ? 1e12 : 1;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        if (currentAllowance < subtractedValue) revert OZError03();
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private  {
        if (owner == address(0) || spender == address(0)) revert OZError04(owner, spender);
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert OZError05(amount);
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    //-----------

    function _subConvertToShares(uint assets_, address account_) private view returns(uint) { 
        return (assets_.mulDivUp(totalShares(), _rETH_ETH())) / _calculateScalingFactor(account_);
    }

    function _convertToShares(uint assets_) private view returns(uint) { 
        return assets_.mulDivUp(totalShares(), _rETH_ETH());
    }

    function totalAssets() public view returns(uint) {
        return _assetsAndShares.extract(TotalType.ASSETS);
    }

    function totalShares() public view returns(uint) {
        return _assetsAndShares.extract(TotalType.SHARES);
    }

    // function totalSupply() public view returns(uint) {
    //     return totalShares() == 0 ? 0 : _subConvertToAssets(totalShares());
    // }

    function totalSupply() public view returns(uint) {
        return totalShares() == 0 ? 0 : 
            _subConvertToAssets(totalShares()) * ((totalAssets() * 1e12) / _subConvertToAssets(totalShares()));
    }

    function sharesOf(address account_) public view returns(uint) {
        return _shares[account_];
    }

    function asset() public view returns(address) {
        return _underlying;
    }

    function balanceOf(address account_) public view returns(uint) {
        return convertToAssets(sharesOf(account_), account_);
    }

    function subBalanceOf(address account_) public view returns(uint) {
        return _subConvertToAssets(sharesOf(account_));
    }

    //test if owner_ being passed to updateReward() affects the owner_ getting the rewards
    //(since the tokens would be going to receiver_ instead of owner_)
    //test using OZLrewards.sol. Perhaps receiver_ needs to be eliminated. If that happens, 
    //remove receiver_ from wozToken.sol - mintAndWrap()
    //receiver_ is also used in ozLoupe
    function mint(
        bytes memory data_, 
        address owner_
    ) external updateReward(owner_, _ozDiamond) returns(uint) { 
        
        (AmountsIn memory amts, address receiver) = 
            abi.decode(data_, (AmountsIn, address));

        uint assets = amts.amountIn.format(FORMAT_DECIMALS); 
        // console.log('assets in mint %%%%%%%: ', assets);

        try ozIDiamond(_ozDiamond).useUnderlying(asset(), owner_, amts) returns(uint amountRethOut) {
            _setValuePerOzToken(amountRethOut, true);

            uint shares = totalShares() == 0 ? assets : previewMint(assets);

            _setAssetsAndShares(assets, shares, true);

            unchecked {
                _shares[receiver] += shares;
                _assets[receiver] += assets;
            }

            return shares;

        } catch Error(string memory reason) {
            revert OZError22(reason);
        }

        //put a mint even here
    }
    //-------------

    function _setValuePerOzToken(uint amountOut_, bool addOrSub_) private {
        ozIDiamond(_ozDiamond).setValuePerOzToken(address(this), amountOut_, addOrSub_);
    }

    function _convertToSharesFromUnderlying(uint assets_) private view returns(uint) {  
        return assets_.mulDivDown(totalShares(), totalAssets());
    }

    function previewMint(uint assets_) public view returns(uint) {
        return _convertToSharesFromUnderlying(assets_);
    }

    function previewRedeem(uint shares_) public view returns(uint) {
        return _convertToAssetsFromUnderlying(shares_);
    }

    function convertToUnderlying(uint shares_) external view returns(uint) {
        return (shares_ * ozIDiamond(_ozDiamond).totalUnderlying(Asset.UNDERLYING)) / totalShares();
    }

    //properly check the data_ that's passed here, like if user's ozAmtIn corresponds to the rEthAmount they're passing also
    function redeem(
        bytes memory data_, 
        address owner_
    ) external updateReward(owner_, _ozDiamond) returns(uint) {

        (AmountsOut memory amts,) = abi.decode(data_, (AmountsOut, address));

        uint256 accountShares = sharesOf(owner_);
        uint shares = subConvertToShares(amts.ozAmountIn, owner_);

        if (accountShares < shares) revert OZError06(owner_, accountShares, shares);


        uint assets = previewRedeem(shares); 
        console.log('');
        console.log('shares: ', shares);
        console.log('accountShares: ', accountShares);
        console.log('totalAssets: ', totalAssets());
        console.log('assets ^^^^^^^^^^^^: ', assets);
        console.log('amts.ozAmountIn: ', amts.ozAmountIn);

        try ozIDiamond(_ozDiamond).useOzTokens(owner_, data_) returns(uint amountRethOut, uint amountAssetOut) {
            _setValuePerOzToken(amountRethOut, false);

            accountShares = sharesOf(_ozDiamond);

            _setAssetsAndShares(assets, accountShares, false);

            unchecked {
                _shares[_ozDiamond] = 0;
                // _assets[owner_] -= assets; 
            }

            console.log('');
            console.log('************ END OF REDEEM ***************');
            console.log('current shares alice: ', sharesOf(owner_));
            console.log('');            

            //put a redeem event here

            return amountAssetOut;
        } catch Error(string memory reason) {
            revert OZError22(reason);
        }

    }


    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) internal {
        if (from == address(0) || to == address(0)) revert OZError04(from, to);

        uint256 shares = convertToShares(amount) / _calculateScalingFactor(from);
        //check if i can put here ^^ another method like subConvertTo_ that joins convery and scaling

        uint256 fromShares = _shares[from];

        if (fromShares < shares) revert OZError07(from, fromShares, shares);

        unchecked {
            _shares[from] = fromShares - shares;
            // Overflow not possible: the sum of all shares is capped by totalShares, and the sum is preserved by
            // decrementing then incrementing.
            _shares[to] += shares;
        }

        emit Transfer(from, to, amount);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets); 
    }

    // function transferShares() external {} <--- https://docs.lido.fi/guides/lido-tokens-integration-guide#transfer-shares-function-for-steth

    //remove the _functions if not needed

    //change all the unit256 to uint ***
    //remove mulDivDown since it divides by 1. 
    function _convertToAssets(uint256 shares_, address account_) private view returns (uint256 assets) {   
        uint preBalance = _subConvertToAssets(shares_);
        // console.log('_convertToAssetsFromUnderlying: ', _convertToAssetsFromUnderlying(shares_));

        console.log('');
        console.log('--- in _convertToAssets ---');
        console.log('preBalance - output of _subConvertToAssets: ', preBalance);
        if (preBalance != 0) {
            console.log('scaling factor: ', _calculateScalingFactor(account_));
            console.log('is: ', preBalance * _calculateScalingFactor(account_));
        }

        return preBalance == 0 ? 0 : preBalance * _calculateScalingFactor(account_);
    }

    function _calculateScalingFactor(address account_) private view returns(uint) {
        uint x = subBalanceOf(account_);
        console.log('');
        console.log('--- in scaling factor');
        console.log('_assets[account_] * 1e12: ', _assets[account_] * 1e12);
        console.log('subBalanceOf(account_): ', x);

        return (_assets[account_] * 1e12) / x;
    }

    function _rETH_ETH() private view returns(uint) { 
        ozIDiamond OZ = ozIDiamond(_ozDiamond);
        return Helpers.rETH_ETH(OZ);
    }

    function _subConvertToAssets(uint256 shares_) private view returns (uint256 assets) { 
        uint reth_eth = _rETH_ETH();

        // console.log('');
        // console.log('--- in _subConvertToAssets ---');
        // console.log('reth_eth: ', reth_eth);
        // console.log('totalShares: ', totalShares());
        // console.log('shares: ', shares_);
        // console.log('is2: ', shares_.mulDivDown(reth_eth, totalShares() == 0 ? reth_eth : totalShares()));

        return shares_.mulDivDown(reth_eth, totalShares() == 0 ? reth_eth : totalShares());
    }

    //this is public instead of private. Check
    function _convertToAssetsFromUnderlying(uint shares_) public view returns(uint) { 
        console.log('');
        console.log('--- in _convertToAssetsFromUnderlying ---');
        console.log('shares: ', shares_);
        console.log('totalShares: ', totalShares());
        console.log('_rETH_ETH(): ', _rETH_ETH());
        console.log('_subConvertToAssets(shares_): ', _subConvertToAssets(shares_));
        // console.log('_convertToAssets: ', _convertToAssets(shares_, 0x37cB1a23e763D2F975bFf3B2B86cFa901f7B517E));
        
        return shares_.mulDivDown(_rETH_ETH(), _subConvertToAssets(shares_));
    }

    
    // function _convertToAssetsFromUnderlying2(uint shares_) private view returns(uint){
    //     console.log('');
    //     console.log('--- in _convertToAssetsFromUnderlying ---');
    //     console.log('shares: ', shares_);
    //     console.log('totalSupply ^^^^^^^^^^^^: ', totalSupply());
        
    //     _convertToAssetsFromUnderlying(shares_);

    //     return shares_.mulDivDown(ozIDiamond(_ozDiamond).getUnderlyingValue(address(this)), totalSupply());
    // }

    function convertToAssets(uint256 shares, address account_) public view returns (uint256 assets) {
        return _convertToAssets(shares, account_);
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return _convertToShares(assets);
    }

    function subConvertToShares(uint256 assets, address account_) public view returns (uint256 shares) {
        return _subConvertToShares(assets, account_);
    }

    //Thoroughly test this function that assets and shares (with extract() from Helpers.sol)
    //are properly extracting and setting up assets/shares where they're supposed to be.
    //Tests can be with minting and redeeming a non-equal part of tokens (check this)
    function _setAssetsAndShares(uint assets_, uint shares_, bool addOrSub_) private {
        uint assets = _assetsAndShares.extract(TotalType.ASSETS); 
        uint shares = _assetsAndShares.extract(TotalType.SHARES); 

        unchecked {
            if (addOrSub_) {
                assets += assets_;
                shares += shares_;
            } else {
                assets -= assets_;
                shares -= shares_;
            }
        }

        _assetsAndShares = bytes32((assets << 128) + shares);
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
        if (block.timestamp > deadline) revert OZError08(deadline, block.timestamp);

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hash, v, r, s_);

        if (signer != owner) revert OZError09(signer, owner);

        _approve(owner, spender, value);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;

}