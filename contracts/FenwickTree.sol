// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

contract FenwickTree {
    uint256 public size;
    mapping(uint256 => uint256) public tree;

    constructor(uint256 _size) {
        size = _size;
    }

    function update(uint256 index, uint256 value) public {
        require(index > 0 && index <= size, "Index out of bounds");
        while (index <= size) {
            tree[index] += value;
            index += index & (~index + 1); // Move to the next index
        }
    }

    function query(uint256 index) public view returns (uint256 sum) {
        require(index > 0 && index <= size, "Index out of bounds");
        while (index > 0) {
            sum += tree[index];
            index -= index & (~index + 1); // Move to the parent index
        }
    }

    function addNumbers(uint256 maxNumber) public {
        for (uint256 i = 1; i <= maxNumber; i++) {
            update(i, i);
        }
    }

    function sumFrom1ToMax(uint256 maxNumber) public view returns (uint256) {
        return query(maxNumber);
    }
}
