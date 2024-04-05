// // SPDX-License-Identifier: GPL-2.0-or-later
// pragma solidity 0.8.21;


// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import {AppStorage, LastRewards, Dir, Pair} from "../../../../contracts/AppStorage.sol";
// import {IPool} from "../../../../contracts/interfaces/IBalancer.sol";
// import {IERC20Permit} from "../../../../contracts/interfaces/IERC20Permit.sol";
// import {ozIToken} from "../../../../contracts/interfaces/ozIToken.sol";
// import {IRocketTokenRETH} from "../../../../contracts/interfaces/IRocketPool.sol";
// import {FixedPointMathLib} from "../../../../contracts/libraries/FixedPointMathLib.sol";
// import {Helpers} from "../../../../contracts/libraries/Helpers.sol";
// import {IERC20Permit} from "../../../../contracts/interfaces/IERC20Permit.sol";
// import {IUsingTellor} from "../../../../contracts/interfaces/IUsingTellor.sol";
// import "../../../../contracts/Errors.sol";


// import {OracleLibrary} from "../../../../contracts/libraries/oracle/OracleLibrary.sol";
// import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

// import "forge-std/console.sol";



// // contract MockOzOraclePreAccrual {

// //     AppStorage private s;


// //     function getUniPrice(uint tokenPair_, Dir side_) public view returns(uint) {
// //         uint amountOut;

// //         if (side_ == Dir.UP) {
// //             amountOut = 1086486906594931900;
// //         } else if (side_ == Dir.DOWN) {
// //             amountOut = 1085995250282916400;
// //         }
    
// //         return amountOut;
// //     }

// //     function _triagePair(uint index_) private view returns(address, address, uint24) {
// //         Pair memory p = s.tokenPairs[index_];
// //         return (p.base, p.quote, p.fee);
// //     }

// // }
