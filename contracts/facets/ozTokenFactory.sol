// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {ozToken} from "../ozToken.sol";
import {AppStorage} from "../AppStorage.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// import "hardhat/console.sol";
// import "forge-std/console.sol";


error TokenAlreadyInRegistry(address erc20);
error CantBeZeroAddress();

contract ozTokenFactory {

    using Helpers for address[];

    AppStorage internal s;

    event TokenCreated(address indexed ozToken);
    
    //Wrapper function - returns address of ozToken
    function createOzToken(
        address underlying_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external returns(address) { //put an onlyOwner

        if (s.ozTokenRegistry.indexOf(underlying_) != -1) revert TokenAlreadyInRegistry(underlying_);
        if (underlying_ == address(0)) revert CantBeZeroAddress();

        //------
        bytes memory data = abi.encodeWithSignature( //use encodeCall here on you have the interface for ozToken
            "initialize(address,address,string,string,uint8)", 
            underlying_, s.ozDiamond, name_, symbol_, decimals_
        );

        BeaconProxy newToken = new BeaconProxy(s.ozBeacon, data);
        //------

        // ozToken newToken = new ozToken(name_, symbol_, underlying_, decimals_, s.ozDiamond);
        s.ozTokenRegistry.push(underlying_);

        emit TokenCreated(address(newToken));

        return address(newToken);
    }

    function getOzTokenRegistry() external view returns(address[] memory) {
        return s.ozTokenRegistry;
    }

    function isInRegistry(address underlying_) public view returns(bool) {
        return s.ozTokenRegistry.indexOf(underlying_) != -1;
    }

}