// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {MockStorage} from "../MockStorage.sol";


contract RethLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(rETHPreAccrual),
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}


contract EthLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(currentPriceETH) / 1e10,
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}


contract SwapRouterMock {

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut) {
        //finish this mock and use it

    }


}