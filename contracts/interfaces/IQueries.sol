// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {IVault} from "./IBalancer.sol";


interface IQueries {
    function querySwap(
        IVault.SingleSwap memory singleSwap, 
        IVault.FundManagement memory funds
    ) external returns (uint256);
}