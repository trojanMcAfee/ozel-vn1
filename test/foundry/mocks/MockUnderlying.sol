// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


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

    // address public foundry = 0x34A1D3fff3958843C43aD80F30b94c510645C316;
    // address public alice = 0x37cB1a23e763D2F975bFf3B2B86cFa901f7B517E;
    // address public bob = 0x16fb7667089738A5055e45Bd0B260845Eaedbe44;
    // address public charlie = 0x2fCF6DA7078728e122af6f1D9762e8356D79630A;
    // address public mockSwapRouterUni = 0x26aFF6f249fDF81492cA987e78f1146296c727b4;
    // address public OZ = 0x26aFF6f249fDF81492cA987e78f1146296c727b4; //check why i need to pass rETH to ozDiamond when in ETH_N_MOCKs is not necessary
    // address public mockVault = 0x7F1f3E02E4B20b47e5E6b3b54893F335D3A41dc1;
    // address public constant ONE = address(1);

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