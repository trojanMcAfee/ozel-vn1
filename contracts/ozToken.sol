// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import "./interfaces/ozIDiamond.sol";
// import "../AppStorage.sol";

import "forge-std/console.sol";


contract ozToken is Context, IERC20, IERC20Metadata { //is AccessControl needed here?

    using FixedPointMathLib for uint;

    // AppStorage private s;

    /**
        Types of balances:
        PT: principal / YT: interests / TT: total
     */
    enum Type {
        PT,
        YT,
        TT
    }

    mapping(Type balanceType  => mapping(address account => uint amount)) private _balances;

    mapping(Type balanceType => mapping(address user => mapping(address spender => uint allowed))) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private immutable _underlying;
    address private immutable _ozDiamond;
    address private _roiMod;

    uint8 private _decimals;

  
    constructor(
        string memory name_, 
        string memory symbol_,
        address underlying_,
        uint8 decimals_,
        address diamond_,
        address roiMod_ //group this in two structs (erc20 and diamond)
    ) {
        _name = name_;
        _symbol = symbol_;
        _underlying = underlying_;
        _decimals = decimals_;
        _ozDiamond = diamond_;
        _roiMod = roiMod_;
    }

    function getDiamond() public view returns(address) {
        return _ozDiamond;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    //mine ***
    function underlying() public view returns(address) {
        return _underlying;
    }

    /**
     * Queries the PT balance of an user/account (principal)
     */
    function balanceOf(address account) public view returns(uint) {
        return _balances[Type.PT][account];
    }

    /**
     * Queries the YT balance of an user/account (interests)
     */
    function interestOf(address account_) public view returns(uint) {
        return _balances[Type.YT][account_];
    }

    /**
     * Queries the TT balance of an user/account (total)
     */
    function totalBalanceOf(address account_) public view returns(uint) {
        return _balances[Type.TT][account_];
    }

   
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Type.PT][owner][spender];
    } //do allowanceYT()

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }


    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    //Mine *******
    function _calculateYT(address from_, uint amount_) private view returns(uint) {
        uint totalPT = _balances[Type.PT][from_];
        uint ratioPT = amount_.fullMulDiv(100 * 1e18, totalPT);
        
        // totalPTbal --- 100%
        // amount_ ------ x = % that amount represents of PT

        // (amount_ * 100) / totalPTbal

        uint totalYT = _balances[Type.YT][from_];
        return ratioPT.fullMulDiv(totalYT, 100 * 1e18); 

        // totalYTbal --- 100%
        //     x ------ ratioPTbal // x = amt of YT based on %

        
    }

    function _calculateNewTT(address from_, address to_) private {
        _balances[Type.TT][from_] = _balances[Type.PT][from_] + _balances[Type.YT][from_];
        _balances[Type.TT][to_] = _balances[Type.PT][to_] + _balances[Type.YT][to_];
    }

   
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[Type.PT][from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {                
            _balances[Type.PT][from] = fromBalance - amount;
            _balances[Type.PT][to] += amount;

            uint toTransferYT = _calculateYT(from, amount);

            _balances[Type.YT][from] -= toTransferYT;
            _balances[Type.YT][from] += toTransferYT;

            _calculateNewTT(from, to);
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }


    function mint(uint amount_) external {
        address erc20 = underlying();
        IERC20 token = IERC20(erc20);
        token.transferFrom(msg.sender, _roiMod, amount_);

        ozIDiamond(_ozDiamond).useUnderlying(
            amount_, erc20, msg.sender
        ); 


    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[Type.PT][account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
    // function _burn(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     _beforeTokenTransfer(account, address(0), amount);

    //     uint256 accountBalance = _balances[account];
    //     require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    //     unchecked {
    //         _balances[account] = accountBalance - amount;
    //         // Overflow not possible: amount <= accountBalance <= totalSupply.
    //         _totalSupply -= amount;
    //     }

    //     emit Transfer(account, address(0), amount);

    //     _afterTokenTransfer(account, address(0), amount);
    // }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[Type.PT][owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

   
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
