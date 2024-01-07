// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";
import {QuoteAsset} from "./interfaces/IOZL.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "forge-std/console.sol";


//Add Permit to this contract
contract OZL is ERC20Upgradeable {

    using FixedPointMathLib for uint;

    address constant rEthAddr = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    bytes32 private constant _OZ_DIAMOND_SLOT = bytes32(uint(keccak256('ozDiamond.storage.slot')) - 1);

    // enum QuoteAsset {
    //     USD,
    //     ETH
    // }

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



    function getBal() public view returns(uint) {
        uint bal = IERC20Permit(rEthAddr).balanceOf(address(this));
        console.log('rETH bal (from fees) ***: ', bal);

        return bal;
    }


    function getExchangeRate(QuoteAsset asset_) public view returns(uint) {
        uint ONE = 1 ether;
        uint totalFeesRETH = IERC20Permit(rEthAddr).balanceOf(address(this));
        uint totalFeesQuote = _convertToQuote(asset_, totalFeesRETH);

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


    function redeem(uint amount_, address receiver_) external returns(uint) {
        

    }


    //--------

    function circulatingSupply() public view returns(uint) {
        return getOZ().getOZLCirculatingSupply();
    }

    function getOZ() public view returns(ozIDiamond) {
        return ozIDiamond(StorageSlot.getAddressSlot(_OZ_DIAMOND_SLOT).value);
    }



    


}