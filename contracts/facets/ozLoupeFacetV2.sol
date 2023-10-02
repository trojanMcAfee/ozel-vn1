// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../AppStorage.sol";


contract ozLoupeFacetV2 {

    AppStorage private s;


    function getDiamondAddr() public view returns(address) {
        return s.ozDiamond;
    }


}