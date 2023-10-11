// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IVault, IAsset} from "../interfaces/IBalancer.sol";


library Helpers {

    function indexOf(
        address[] memory array_, 
        address value_
    ) internal pure returns(int) 
    {
        uint length = array_.length;
        for (uint i=0; i < length; i++) {
            if (address(array_[i]) == value_) return int(i);
        }
        return -1;
    }

    function remove(uint[] storage arr, uint index) internal { //not used so far
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

    function convertToDynamic(address[3] memory addr_) internal pure returns(address[] memory array) {
        uint length = addr_.length;
        array = new address[](length);
        
        for (uint i=0; i < length; i++) {
            array[i] = addr_[i];
        }
    }

    function convertToDynamic(uint[3] memory amts_) internal pure returns(uint[] memory array) {
        uint length = amts_.length;
        array = new uint[](length);
        
        for (uint i=0; i < length; i++) {
            array[i] = amts_[i];
        }
    }

    function convertToDynamic(uint[2] memory amts_) internal pure returns(uint[] memory array) {
        uint length = amts_.length;
        array = new uint[](length);
        
        for (uint i=0; i < length; i++) {
            array[i] = amts_[i];
        }
    }

}