// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {IVault} from "../../contracts/interfaces/IBalancer.sol";
import {TradeAmounts, TradeAmountsOut} from "../../contracts/AppStorage.sol";


enum Type {
    IN,
    OUT
}

struct RequestType {
    IVault.JoinPoolRequest join;
    IVault.ExitPoolRequest exit;
    TradeAmounts amtsIn;
    TradeAmountsOut amtsOut;
    Type req;
}