// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {AppStorage, Deposit} from "./../AppStorage.sol";


import "forge-std/console.sol";

contract ozFenwickTree {

    AppStorage internal s;


    // uint256 public size;
    // mapping(uint256 => uint256) public tree;
    // mapping(address user => Deposit[] deposits) tree;

    // constructor(uint256 _size) {
    //     size = _size; 
    // }

    // function update(uint index, Deposit deposit_) public {
    //     require(index > 0 && index <= size, "Index out of bounds"); //put a custom error here
    //     uint localIndex = index; // Cache index in memory
    //     uint cachedSize = size; // Cache size in memory

    //     while (localIndex <= cachedSize) {
    //         tree[localIndex] += value;
    //         localIndex += localIndex & (~localIndex + 1); // Move to the next index
    //     }
    // }


    function updateDeposit(uint256 index, uint256 value) external {
        require(index > 0 && index <= s.size, "Index out of bounds");
        uint256 localIndex = index; // Cache index in memory
        uint256 cachedSize = s.size; // Cache size in memory

        while (localIndex <= cachedSize) {
            s.depositTree[localIndex] += value;
            localIndex += localIndex & (~localIndex + 1); // Move to the next index
        }
    }

    //Fix sintax in all of these functions
    function updateFactor(address user, uint256 index, uint256 value) external {
        require(index > 0 && index <= s.size, "Index out of bounds");
        uint256 localIndex = index; // Cache index in memory
        uint256 cachedSize = s.size; // Cache size in memory

        while (localIndex <= cachedSize) {
            s.contributionFactors[user][localIndex] += value;
            localIndex += localIndex & (~localIndex + 1); // Move to the next index
        }
    }


    function queryFactor(address user, uint256 index) external view returns (uint256 sum) {
        require(index > 0 && index <= s.size, "Index out of bounds");
        uint256 localIndex = index; // Cache index in memory

        while (localIndex > 0) {
            sum += s.contributionFactors[user][localIndex];
            localIndex -= localIndex & (~localIndex + 1); // Move to the parent index
        }
    }


    function queryDeposit(uint256 index) external view returns (uint256 sum) {
        require(index > 0 && index <= s.size, "Index out of bounds");
        uint256 localIndex = index; // Cache index in memory

        while (localIndex > 0) {
            sum += s.depositTree[localIndex];
            localIndex -= localIndex & (~localIndex + 1); // Move to the parent index
        }
    }

    // function query(uint256 index) public view returns (uint256 sum) {
    //     require(index > 0 && index <= size, "Index out of bounds");
    //     uint256 localIndex = index; // Cache index in memory

    //     while (localIndex > 0) {
    //         sum += tree[localIndex];
    //         localIndex -= localIndex & (~localIndex + 1); // Move to the parent index
    //     }
    // }





    // function addNumbers(uint256 maxNumber) public {
    //     for (uint256 i = 1; i <= maxNumber; i++) {
    //         update(i, i);
    //     }
    // }

    // function sumFrom1ToMax(uint256 maxNumber) public view returns (uint256) {
    //     return query(maxNumber);
    // }
}
