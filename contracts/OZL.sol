// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";

import "forge-std/console.sol";

//Add Permit to this contract
contract OZL is ERC20Upgradeable {

    using FixedPointMathLib for uint;

    address constant rEthAddr = 0xae78736Cd615f374D3085123A210448E74Fc6393;
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



    function getBal() public view returns(uint) {
        uint bal = IERC20Permit(rEthAddr).balanceOf(address(this));
        console.log('rETH bal (from fees) ***: ', bal);

        return bal;
    }


    function getExchangeRate() public view returns(uint) {
        uint ONE = 1;
        uint totalFees = IERC20Permit(rEthAddr).balanceOf(address(this));
        uint ozlSupply = totalSupply();

        if (ozlSupply == 0) return ONE;

        return ONE.mulDivDown(totalFees, ozlSupply); //ozlSupply must be circulating supply
    }

    function circulatingSupply() public view returns(uint) {
        ozIDiamond OZ = ozIDiamond(StorageSlot.getAddressSlot(_OZ_DIAMOND_SLOT).value);
        return OZ.getOZLCirculatingSupply();
    }

    


}