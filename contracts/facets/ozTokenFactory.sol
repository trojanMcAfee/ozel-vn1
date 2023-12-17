// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {ozToken} from "../ozToken.sol";
import {AppStorage} from "../AppStorage.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {ozTokenProxy} from "../ozTokenProxy.sol";
import {ozIToken} from "../interfaces/ozIToken.sol";
import "../Errors.sol";
// import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// import "hardhat/console.sol";
import "forge-std/console.sol";




contract ozTokenFactory {

    using Helpers for address[];

    AppStorage internal s;

    event TokenCreated(address indexed ozToken);
    
    //Wrapper function - returns address of ozToken
    function createOzToken(
        address underlying_,
        string memory name_,
        string memory symbol_
    ) external returns(address) { //put an onlyOwner

        if (isInRegistry(underlying_)) revert OZError12(underlying_);
        if (underlying_ == address(0)) revert OZError11(underlying_);

        //------
        bytes memory data = abi.encodeWithSignature( 
            "initialize(address,address,string,string)", 
            underlying_, s.ozDiamond, name_, symbol_
        );

        ozTokenProxy newToken = new ozTokenProxy(s.ozBeacon, data);
        //------

        console.log('address(newToken): ', address(newToken));

        s.ozTokenRegistry.push(address(newToken));

        emit TokenCreated(address(newToken));

        return address(newToken);
    }

    function getOzTokenRegistry() external view returns(address[] memory) {
        return s.ozTokenRegistry;
    }

    function isInRegistry(address underlying_) public view returns(bool) {
        uint length = s.ozTokenRegistry.length;
        if (length == 0) return false;

        for (uint i=0; i < length; i++) {
            if (ozIToken(s.ozTokenRegistry[i]).asset() == underlying_) return true; 
        }

        return false;
    }

    

}