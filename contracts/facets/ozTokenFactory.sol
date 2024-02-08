// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {ozToken} from "../ozToken.sol";
import {AppStorage, NewToken, OzTokens} from "../AppStorage.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {ozTokenProxy} from "../ozTokenProxy.sol";
import {wozTokenProxy} from "../wozTokenProxy.sol";
import {ozIToken} from "../interfaces/ozIToken.sol";
import "../Errors.sol";
// import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// import "hardhat/console.sol";
import "forge-std/console.sol";


//Put here, inside createOzToken, the creation of the wozToken also. 
//I added already all to Setup.sol
//What's left is to create the wozToken contract and call the getHello function
//on the implementation to see if it works (use as guide ozToken.sol)


contract ozTokenFactory {

    AppStorage internal s;

    event TokenCreated(address indexed ozToken, address indexed wozToken);

    
    //Wrapper function - returns address of ozToken
    function createOzToken(
        address underlying_,
        NewToken memory ozToken_,
        NewToken memory wozToken_
    ) external returns(address, address) { //put an onlyOwner or onlyRole

        if (isInRegistry(underlying_)) revert OZError12(underlying_);
        if (underlying_ == address(0)) revert OZError11(underlying_);

        //ozToken
        bytes memory ozData = abi.encodeWithSignature( 
            "initialize(address,address,string,string)", 
            underlying_, s.ozDiamond, ozToken_.name, ozToken_.symbol
        );

        ozTokenProxy newToken = new ozTokenProxy(address(this), ozData, 0);
        
        //wozToken
        bytes memory wozData = abi.encodeWithSignature(
            "initialize(string,string,address)", 
            wozToken_.name, wozToken_.symbol, address(newToken)
        );

        wozTokenProxy newWozToken = new wozTokenProxy(address(this), wozData, 1);

        //------
        OzTokens memory ozTokens = OzTokens(address(newToken), address(newWozToken));

        _saveInRegistry(ozTokens, underlying_); 

        return (address(newToken), address(newWozToken));
    }

    //check if i can emit event with structs: https://ethereum.stackexchange.com/questions/159698/structs-in-events
    function _saveInRegistry(OzTokens memory newOzTokens_, address underlying_) private {
        s.ozTokenRegistry.push(newOzTokens_);
        s.ozTokens[underlying_] = newOzTokens_.ozToken;
        emit TokenCreated(newOzTokens_.ozToken, newOzTokens_.wozToken);
    }

    function getOzTokenRegistry() external view returns(OzTokens[] memory) {
        return s.ozTokenRegistry;
    }

    function isInRegistry(address underlying_) public view returns(bool) {
        uint length = s.ozTokenRegistry.length;
        if (length == 0) return false;

        for (uint i=0; i < length; i++) {
            if (ozIToken(s.ozTokenRegistry[i].ozToken).asset() == underlying_) return true; 
        }

        return false;
    }

    

}