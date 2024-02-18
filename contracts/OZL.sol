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
import {OZLrewards} from "./AppStorage.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/draft-EIP712Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/CountersUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/ECDSAUpgradeable.sol";
import {Helpers} from "./libraries/Helpers.sol";
import "./Errors.sol";

import "forge-std/console.sol";


//Add Permit to this contract
contract OZL is ERC20Upgradeable, EIP712Upgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using FixedPointMathLib for uint;
    using Helpers for address;
    using Helpers for address[];

    bytes32 private constant _OZ_DIAMOND_SLOT = bytes32(uint(keccak256('ozDiamond.storage.slot')) - 1);

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => CountersUpgradeable.Counter) private _nonces;


    constructor() {
        _disableInitializers();
    }


    function initialize(
        string memory name_, 
        string memory symbol_,
        address ozDiamond_,
        address teamVestingWallet_,
        address guildVestingWallet_,
        uint totalSupply_,
        uint communityAmount_,
        uint teamAmount_,
        uint guildAmount_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __EIP712_init(name_, "1");
        StorageSlot.getAddressSlot(_OZ_DIAMOND_SLOT).value = ozDiamond_;

        _mint(address(this), totalSupply_); 
        _transfer(address(this), ozDiamond_, communityAmount_);
        _transfer(address(this), teamVestingWallet_, teamAmount_);
        _transfer(address(this), guildVestingWallet_, guildAmount_);
    }



    function getExchangeRate() external view returns(uint) {
        return getExchangeRate(QuoteAsset.USD);
    }


    function getExchangeRate(QuoteAsset asset_) public view returns(uint) {
        uint ONE = 1 ether;
        uint totalFeesLSD;

        uint length = _LSDs().length;
        for (uint i=0; i<length; i++) {
            totalFeesLSD += IERC20(_LSDs()[i]).balanceOf(address(this));
        }

        uint totalFeesQuote = asset_ == QuoteAsset.rETH ?
         totalFeesLSD : 
         _convertToQuote(asset_, totalFeesLSD);

        uint c_Supply = circulatingSupply();

        if (c_Supply == 0) return ONE;

        return ONE.mulDivDown(totalFeesQuote, c_Supply);
    }


    function _convertToQuote(QuoteAsset qt_, uint totalFeesRETH_) private view returns(uint quote) {
        if (qt_ == QuoteAsset.USD) {
            quote = totalFeesRETH_.mulDivDown(getOZ().rETH_USD(), 1 ether);
        } else if(qt_ == QuoteAsset.ETH) 
        {
            bytes memory data = abi.encodeWithSignature('rETH_ETH()');
            data = Address.functionStaticCall(address(getOZ()), data);
            //^^^ put here rETH_ETH() from Helpers.sol
            
            uint reth_eth = abi.decode(data, (uint));
            quote = totalFeesRETH_.mulDivDown(reth_eth, 1 ether);
        }
    }


    function redeem(
        address owner_,
        address receiver_,
        address tokenOut_,
        uint256 ozlAmountIn_,
        uint[] memory minAmountsOut_
    ) external returns(uint amountOut) {
        ozIDiamond OZ = getOZ();

        address[] memory LSDs = _LSDs();

        if (
            OZ.ozTokens(tokenOut_) == address(0) &&
            LSDs.indexOf(tokenOut_) < 0
        ) revert OZError18(tokenOut_);

        if (msg.sender != owner_) {
            _spendAllowance(owner_, msg.sender, ozlAmountIn_);
        }

        uint rETHtoRedeem = ozlAmountIn_.mulDivDown(getExchangeRate(QuoteAsset.rETH), 1 ether);

        OZ.recicleOZL(owner_, address(this), ozlAmountIn_);
        
        //rETH branch
        if (tokenOut_ == LSDs[0]) {
            if (rETHtoRedeem < minAmountsOut_[0]) revert OZError19(rETHtoRedeem);

            SafeERC20.safeTransfer(IERC20(LSDs[0]), receiver_, rETHtoRedeem);
            return rETHtoRedeem;
        }

        return OZ.useOZL( 
            tokenOut_,
            receiver_,
            rETHtoRedeem,
            minAmountsOut_
        );

        // emit Withdraw(msg.sender, receiver_, owner_, assets, shares);
    }


    //make this two totalSupplies()
    function circulatingSupply() public view returns(uint) {
        (,uint c_supply,,,) = getOZ().getRewardsData();
        return c_supply;
    }

    function recicledSupply() public view returns(uint) {
        (,,,uint r_supply,) = getOZ().getRewardsData();
        return r_supply;
    }

    function getOZ() public view returns(ozIDiamond) {
        return ozIDiamond(StorageSlot.getAddressSlot(_OZ_DIAMOND_SLOT).value);
    }

    function _LSDs() private view returns(address[] memory) {
        return getOZ().getLSDs();
    }

   
    //--------

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