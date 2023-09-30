// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {ozToken} from "./ozToken.sol";
import {AppStorage} from "../AppStorage.sol";


error TokenNotInRegistry(address erc20);

contract ozTokenFactory {

    AppStorage internal s;

    
    //Wrapper function
    function createToken(address erc20_, uint amount_) external view returns(address) { //returns address of ozToken

        if (!s.ozTokenRegistry[erc20_]) revert TokenNotInRegistry(erc20_);

        return erc20_;

    }

}