// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;



library Helpers {

    function indexOf(
        address[] memory array_, 
        address value_
    ) internal pure returns(int) 
    {
        uint length = array_.length;
        for (uint i=0; i < length; i++) {
            if (address(array_[i]) == value_) return int(i);
        }
        return -1;
    }

}