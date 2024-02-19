// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IVault} from "../../contracts/interfaces/IBalancer.sol";
import {AmountsIn, AmountsOut} from "../../contracts/AppStorage.sol";


enum Type {
    IN,
    OUT
}

enum Dir {
    UP,
    DOWN
}

struct RequestType {
    IVault.JoinPoolRequest join;
    IVault.ExitPoolRequest exit;
    AmountsIn amtsIn;
    AmountsOut amtsOut;
    Type req;
}

struct ReqIn {
    address ozERC20Addr;
    address ethUsdChainlink;
    address rEthEthChainlink;
    address testToken;
    address wethAddr;
    address rEthWethPoolBalancer;
    address rEthAddr;
    uint defaultSlippage;
    uint amountIn;
}

struct ReqOut {
    address ozERC20Addr;
    address wethAddr;
    address rEthWethPoolBalancer;
    address rEthAddr;
    uint amountIn;
    uint defaultSlippage;
}