// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IVault {
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);
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