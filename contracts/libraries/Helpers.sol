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

    function createSingleSwap(
        bytes32 poolId_,
        IVault.SwapKind kind_,
        IAsset assetIn_,
        IAsset assetOut_,
        uint amountIn_
    ) internal pure returns(IVault.SingleSwap memory singleSwap) {
        singleSwap = IVault.SingleSwap({
            poolId: poolId_,
            kind: kind_,
            assetIn: assetIn_,
            assetOut: assetOut_,
            amount: amountIn_,
            userData: new bytes(0)
        });
    }

    function createFundMngmt(
        address sender_,
        address payable recipient_
    ) internal pure returns(IVault.FundManagement memory fundMngmt) {
        fundMngmt = IVault.FundManagement({
            sender: sender_,
            fromInternalBalance: false,
            recipient: recipient_,
            toInternalBalance: false
        });
    }

    function remove(uint[] storage arr, uint index) internal { //not used so far
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

}