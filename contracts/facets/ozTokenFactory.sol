// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozToken} from "./ozToken.sol";
import {AppStorage} from "../AppStorage.sol";
import {Helpers} from "../../libraries/Helpers.sol";

// import "hardhat/console.sol";


error TokenAlreadyInRegistry(address erc20);
error CantBeZeroAddress();

contract ozTokenFactory {

    using Helpers for address[];

    AppStorage internal s;

    
    //Wrapper function - returns address of ozToken
    function createOzToken(
        address erc20_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external returns(address) { //put an onlyOwner

        if (s.ozTokenRegistry.indexOf(erc20_) != -1) revert TokenAlreadyInRegistry(erc20_);
        if (erc20_ == address(0)) revert CantBeZeroAddress();

        ozToken newToken = new ozToken(name_, symbol_, erc20_, decimals_);
        s.ozTokenRegistry.push(erc20_);

        return address(newToken);
    }

    function getOzTokenRegistry() external view returns(address[] memory) {
        return s.ozTokenRegistry;
    }

    function isInRegistry(address erc20_) public view returns(bool) {
        return s.ozTokenRegistry.indexOf(erc20_) != -1;
    }

}