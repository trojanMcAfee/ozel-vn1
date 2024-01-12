// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {QuoteAsset} from "./interfaces/IOZL.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TradingLib} from "./libraries/TradingLib.sol";
import {TradingPackage} from "./AppStorage.sol";
import "./Errors.sol";

import "forge-std/console.sol";


//Add Permit to this contract
contract OZL is ERC20Upgradeable {

    using FixedPointMathLib for uint;

    bytes32 private constant _OZ_DIAMOND_SLOT = bytes32(uint(keccak256('ozDiamond.storage.slot')) - 1);


    constructor() {
        _disableInitializers();
    }


    function initialize(
        string memory name_, 
        string memory symbol_,
        address ozDiamond_,
        uint totalSupply_,
        uint communityAmount_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        StorageSlot.getAddressSlot(_OZ_DIAMOND_SLOT).value = ozDiamond_;

        /**
         * Add here later the vesting strategy using
         * OP's VestingWallet.sol / https://medium.com/cardstack/building-a-token-vesting-contract-b368a954f99
         * Use linear distribution, not all unlocked at once.
         * When they vest, add it to circulating supply.
         */
        _mint(address(this), totalSupply_); 
        _transfer(address(this), ozDiamond_, communityAmount_);
    }



    function getExchangeRate() external view returns(uint) {
        return this.getExchangeRate(QuoteAsset.USD);
    }


    function getExchangeRate(QuoteAsset asset_) public view returns(uint) {
        uint ONE = 1 ether;
        address rETH = getOZ().tradingPackage().rETH;
        uint totalFeesRETH = IERC20Permit(rETH).balanceOf(address(this));

        uint totalFeesQuote = asset_ == QuoteAsset.rETH ?
         totalFeesRETH : 
         _convertToQuote(asset_, totalFeesRETH);

        uint c_Supply = circulatingSupply();

        if (c_Supply == 0) return ONE;

        return ONE.mulDivDown(totalFeesQuote, c_Supply);
    }


    function _convertToQuote(QuoteAsset qt_, uint totalFeesRETH_) private view returns(uint) {
        bytes memory data = abi.encodeWithSignature('rETH_ETH()');
        data = Address.functionStaticCall(address(getOZ()), data);

        uint reth_eth = abi.decode(data, (uint));

        uint quote;

        if (qt_ == QuoteAsset.USD) {
            quote = totalFeesRETH_.mulDivDown(getOZ().rETH_USD(), 1 ether);
        } else if(qt_ == QuoteAsset.ETH) {
            quote = totalFeesRETH_.mulDivDown(reth_eth, 1 ether);
        }

        return quote;
    }


    function redeem(
        address owner_,
        address receiver_,
        address tokenOut_,
        uint256 ozlAmountIn_,
        uint[] memory minAmountsOut_
    ) external returns(uint amountOut) {
        ozIDiamond OZ = getOZ();
        TradingPackage memory p = OZ.tradingPackage();

        if (
            OZ.ozTokens(tokenOut_) == address(0) &&
            tokenOut_ != p.WETH &&
            tokenOut_ != p.rETH
        ) revert OZError18(tokenOut_);

        if (msg.sender != owner_) {
            _spendAllowance(owner_, msg.sender, ozlAmountIn_);
        }

        //grabs rETH from the contract and swaps it for tokenOut_
        uint usdValue = ozlAmountIn_.mulDivDown(getExchangeRate(QuoteAsset.USD), 1 ether);
        uint rETHtoRedeem = usdValue.mulDivDown(1 ether, OZ.rETH_USD());

        if (tokenOut_ == p.rETH) {
            if (rETHtoRedeem < minAmountsOut_[0]) revert OZError19(rETHtoRedeem);
            return TradingLib.sendLSD(p.rETH, receiver_, rETHtoRedeem);
        }

        return TradingLib.useOZL( 
            p,
            owner_,
            tokenOut_,
            receiver_,
            address(OZ),
            ozlAmountIn_,
            rETHtoRedeem,
            minAmountsOut_
        );

        // emit Withdraw(msg.sender, receiver_, owner_, assets, shares);
    }


    function circulatingSupply() public view returns(uint) {
        return getOZ().getOZLCirculatingSupply();
    }

    function getOZ() public view returns(ozIDiamond) {
        return ozIDiamond(StorageSlot.getAddressSlot(_OZ_DIAMOND_SLOT).value);
    }


    //--------


    /**
     * @notice Returns the EIP-712 DOMAIN_SEPARATOR.
     * @return A bytes32 value representing the EIP-712 DOMAIN_SEPARATOR.
     */
    // function DOMAIN_SEPARATOR() external view returns (bytes32) {
    //     return _domainSeparatorV4();
    // }

    // /**
    //  * @notice Returns the current nonce for the given owner address.
    //  * @param owner The address whose nonce is to be retrieved.
    //  * @return The current nonce as a uint256 value.
    //  */
    // function nonces(address owner) external view returns (uint256) {
    //     return _nonces[owner].current();
    // }

    // /**
    //  * @dev Private function that increments and returns the current nonce for a given owner address.
    //  * @param owner The address whose nonce is to be incremented.
    //  */
    // function _useNonce(address owner) private returns (uint256 current) {
    //     CountersUpgradeable.Counter storage nonce = _nonces[owner];
    //     current = nonce.current();

    //     nonce.increment();
    // }

    // /**
    //  * @notice Allows an owner to approve a spender with a one-time signature, bypassing the need for a transaction.
    //  * @dev Uses the EIP-2612 standard.
    //  * @param owner The address of the token owner.
    //  * @param spender The address of the spender.
    //  * @param value The amount of tokens to be approved.
    //  * @param deadline The expiration time of the signature, specified as a Unix timestamp.
    //  * @param v The recovery byte of the signature.
    //  * @param r The first 32 bytes of the signature.
    //  * @param s_ The second 32 bytes of the signature.
    //  */
    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s_
    // ) external {
    //     if (block.timestamp > deadline) revert OZError08(deadline, block.timestamp);

    //     bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
    //     bytes32 hash = _hashTypedDataV4(structHash);
    //     address signer = ECDSAUpgradeable.recover(hash, v, r, s_);

    //     if (signer != owner) revert OZError09(owner, spender);

    //     _approve(owner, spender, value);
    // }

    // /**
    //  * @dev This empty reserved space is put in place to allow future versions to add new
    //  * variables without shifting down storage in the inheritance chain.
    //  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    //  */
    // uint256[42] private __gap;
    


}