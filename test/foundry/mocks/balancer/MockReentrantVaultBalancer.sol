// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {IAsset} from "./../../../../contracts/interfaces/IBalancer.sol";
import {ozIToken} from "./../../../../contracts/interfaces/ozIToken.sol";


contract MockReentrantVaultBalancer {

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    address deadAddr = 0x000000000000000000000000000000000000dEaD;

    address immutable ozERC20addr;

    constructor(ozIToken ozToken_) {
        ozERC20addr = address(ozToken_);
    }


    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint) {
        bytes memory data = abi.encode(singleSwap, funds, limit, deadline);
        ozIToken(ozERC20addr).redeem(data, deadAddr);
    }

}