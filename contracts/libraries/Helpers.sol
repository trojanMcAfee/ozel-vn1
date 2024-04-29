// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IVault, IAsset} from "../interfaces/IBalancer.sol";
import {IERC20Permit} from "../interfaces/IERC20Permit.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {stdMath} from "../../lib/forge-std/src/StdMath.sol";

enum TotalType {
    ASSETS,
    SHARES
}


library Helpers {

    using FixedPointMathLib for uint;
    using Address for address;



    function extract(bytes32 assetsAndShares_, TotalType type_) internal pure returns(uint) {
        uint MASK = 2 ** (128) - 1;
        
        return type_ == TotalType.ASSETS ? 
            uint(assetsAndShares_ >> 128) & MASK :
            uint(assetsAndShares_) & MASK;
    }



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

    function replace(address[] storage arr, uint index, address newElement) internal {
        // arr[index] = arr[arr.length - 1];
        // arr.pop();
        index == 0 ? arr[0] = newElement : arr[1] = newElement;
    }

    function calculateMinAmountOut(
        uint256 amount_,
        uint16 slippage_
    ) internal pure returns(uint256) {
        return amount_ - amount_.mulDivDown(uint(slippage_), 10_000);
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

    function createRequest( //perhaps join these two (below)
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

    function formatMinOut(uint minOut_, address tokenOut_) internal view returns(uint) {
        uint decimals = IERC20Permit(tokenOut_).decimals();
        return decimals == 18 ? minOut_ : minOut_ / 10 ** (18 - decimals);
    }

    function format(uint num_, uint decimals_) internal pure returns(uint) {
        return num_ / decimals_;
    }

    function min(uint x, uint y) internal pure returns(uint) {
        return x <= y ? x : y;
    }

    function compareStrings(
        string memory str1_,
        string memory str2_
    ) internal pure returns(bool) {
        return keccak256(abi.encodePacked(str1_)) == keccak256(abi.encodePacked(str2_));
    }

    function rETH_ETH(ozIDiamond OZ_) internal view returns(uint) {
        bytes memory data = abi.encodeWithSignature('rETH_ETH()');
        data = Address.functionStaticCall(address(OZ_), data);
        return abi.decode(data, (uint));
    }

    function calculateMinAmountOut(
        uint amountIn_,
        uint price_, 
        uint16 slippage_
    ) internal pure returns(uint minAmountOut) {
        uint amountOut = amountIn_.mulDivDown(price_, 1 ether);
        minAmountOut = amountOut - amountOut.mulDivDown(uint(slippage_), 10_000);
    }


    function getMedium(uint num1, uint num2, uint num3) internal pure returns (uint) {
        if ((num1 >= num2 && num1 <= num3) || (num1 <= num2 && num1 >= num3)) {
            return num1;
        } else if ((num2 >= num1 && num2 <= num3) || (num2 <= num1 && num2 >= num3)) {
            return num2;
        } else {
            return num3;
        }
    }

    function getMedium(uint num1, uint num2) internal pure returns(uint) {
        return (num1 + num2) / 2;
    }


    function checkDeviation( 
        uint mainAmount_, 
        uint referenceAmount_, 
        uint16 bps_
    ) internal pure returns(bool) {
        uint delta = stdMath.abs(int(referenceAmount_) - int(mainAmount_));
        return uint(bps_) > delta.mulDivDown(10_000, mainAmount_);
    }
  
}