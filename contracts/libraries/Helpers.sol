// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IVault, IAsset} from "../interfaces/IBalancer.sol";
import "solady/src/utils/FixedPointMathLib.sol";


library Helpers {

    using FixedPointMathLib for uint;

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

    function calculateMinAmountOut(
        uint256 amount_,
        uint slippage_
    ) internal pure returns(uint256) {
        return amount_ - amount_.fullMulDiv(slippage_, 10000);
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

    function convertToDynamics(
        address[3] memory addr_,
        uint minOut_
    ) internal pure returns(
        address[] memory assets,
        uint[] memory maxAmountsIn,
        uint[] memory amountsIn
    ) {
        assets = convertToDynamic(addr_);
        maxAmountsIn = convertToDynamic([0, 0, minOut_]);
        amountsIn = convertToDynamic([0, minOut_]);
    }

    function createUserData( //join this func and below into one (do the kind separation here, in func body)
        IVault.JoinKind kind_,
        uint[] memory amountsIn_, 
        uint minBptOut_
    ) internal pure returns(bytes memory) {
        return abi.encode( 
            kind_,
            amountsIn_,
            minBptOut_
        );
    }

    function createUserData(
        IVault.ExitKind kind_,
        uint bptAmountIn_, 
        uint exitTokenIndex_
    ) internal pure returns(bytes memory) {
        return abi.encode( 
            kind_,
            bptAmountIn_,
            exitTokenIndex_
        );
    }

    function createRequest(
        address[] memory assets_,
        uint[] memory maxAmountsIn_, 
        bytes memory userData_
    ) internal pure returns(IVault.JoinPoolRequest memory) { 
        return IVault.JoinPoolRequest({
            assets: assets_,
            maxAmountsIn: maxAmountsIn_,
            userData: userData_,
            fromInternalBalance: false
        });
    }

    function createExitRequest(
        address[] memory assets_,
        uint[] memory minAmountsOut_,
        bytes memory userData_
    ) internal pure returns(IVault.ExitPoolRequest memory) {
        return IVault.ExitPoolRequest({
            assets: assets_,
            minAmountsOut: minAmountsOut_,
            userData: userData_,
            toInternalBalance: false
        });
    }

}