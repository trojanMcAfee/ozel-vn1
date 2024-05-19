// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {console} from "forge-std/console.sol";

//Mocks the underlying stablecoin, either 6 decimals like USDC or 18 decimals like DAI
contract MockUnderlying is ERC20 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint8 dec;
    uint constant MAX_UINT = type(uint).max;
    // uint public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public PERMIT_TYPEHASH;


    constructor(uint dec_) ERC20("Mock", "MOCK") {
        dec = uint8(dec_);
    }


    function mint(address to_, uint amount_) external {
        _mint(to_, amount_);
    }


    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    // function DOMAIN_SEPARATOR() external view override returns (bytes32) {
    //     return _domainSeparatorV4();
    // }

    function decimals() public view override returns (uint8) {
        return dec;
    }

    // function getExchangeRate() external view returns(uint) {

    // }

}