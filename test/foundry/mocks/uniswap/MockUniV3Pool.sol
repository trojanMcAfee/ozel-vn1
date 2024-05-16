// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


contract MockUniV3Pool {

    function observe(uint32[] calldata secondsAgos) external pure returns(
        int56[] memory, 
        uint160[] memory
    ) {
        int56[] memory tickCumulatives = new int56[](2);
        uint160[] memory secondsPerLiquidityCumulativeX128s = new uint160[](1);

        if (secondsAgos[0] == 1800) {
            tickCumulatives[0] = int56(27639974418);
            tickCumulatives[1] = int56(27641473818);
        } else {
            tickCumulatives[0] = int56(27569616390);
            tickCumulatives[1] = int56(27641473818);
        }

        return (tickCumulatives, secondsPerLiquidityCumulativeX128s);
    }

}