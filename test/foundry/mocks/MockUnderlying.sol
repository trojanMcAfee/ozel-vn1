// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {console} from "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


//Mocks the underlying stablecoin, either 6 decimals like USDC or 18 decimals like DAI
contract MockUnderlying is ERC20 {

    uint8 dec;
    uint public nonces;
    uint t_supply;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public PERMIT_TYPEHASH;

    address public foundry = 0x34A1D3fff3958843C43aD80F30b94c510645C316;
    address public alice = 0x37cB1a23e763D2F975bFf3B2B86cFa901f7B517E;

    constructor(uint dec_) ERC20("Mock", "MOCK") {
        dec = uint8(dec_);
        t_supply = 100_000_000 * 10 ** dec_;
    }


    function decimals() public view override returns (uint8) {
        return dec;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        return spender != address(0) && amount > 0;
    }

    function balanceOf(address user) public view override returns(uint) {
        return user == alice && msg.sender == foundry ? 1: 0;
    }

    function totalSupply() public view override returns (uint256) {
        return t_supply;
    }

    // function transfer(address to, uint256 amount) public override returns (bool) {

    // }
}