// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


contract MockUniV3Pool {

    function observe(uint32[] calldata secondsAgos) external view returns(
        int56[] memory tickCumulatives, 
        uint160[] memory secondsPerLiquidityCumulativeX128s
    ) {
        if (secondsAgos.length > 0) {
            tickCumulatives[0] = int56(27639974418);
            tickCumulatives[1] = int56(27641473818);
        }
    }

}