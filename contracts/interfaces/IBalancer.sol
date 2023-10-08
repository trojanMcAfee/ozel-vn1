// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IVault {
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

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

    struct JoinPoolRequest {
        address[] assets,
        uint256[] maxAmountsIn,
        bytes userData,
        bool fromInternalBalance
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest request
    ) external payable;
}

interface IPool {
    function getPoolId() external view returns(bytes32);

    function getPausedState()
    external
    view
    returns (
        bool paused,
        uint256 pauseWindowEndTime,
        uint256 bufferPeriodEndTime
    );
}

interface IQueries {
    function querySwap(IVault.SingleSwap memory singleSwap, IVault.FundManagement memory funds)
        external
        returns (uint256);
}