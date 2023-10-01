// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/access/AccessControl.sol';

// contract ozToken2 is ERC20 { //add AccessControl here

//     uint private constant _BASE = 1e18;

//     uint public rewardMultiplier;

//     bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

//     constructor(
//         string memory name_, 
//         string memory symbol_
//     ) ERC20(name_, symbol_) {

//     }

//     function convertToTokens(uint shares_) public view returns(uint) {
//         return (shares_ * rewardMultiplier) * _BASE;
//     }


    
//     /**
//         Multiplier functions
//      */
//     function addRewardMultiplier(uint256 _rewardMultiplierIncrement) external { //onlyRole(ORACLE_ROLE)
//         if (_rewardMultiplierIncrement == 0) {
//             // revert USDMInvalidRewardMultiplier(_rewardMultiplierIncrement);
//             revert();
//         }

//         _setRewardMultiplier(rewardMultiplier + _rewardMultiplierIncrement);
//     }


//     function _setRewardMultiplier(uint256 _rewardMultiplier) private {
//         if (_rewardMultiplier < _BASE) {
//             // revert USDMInvalidRewardMultiplier(_rewardMultiplier);
//             revert();
//         }

//         rewardMultiplier = _rewardMultiplier;

//         // emit RewardMultiplier(rewardMultiplier);
//     }


// }



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metada.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "solady/src/utils/FixedPointMathLib.sol";


contract ozToken is Context, IERC20, IERC20Metadata {

    using FixedPointMathLib for uint;

    /**
        Types of balances:
        PT: principal / YT: interests / TT: total
     */
    enum Type {
        PT,
        YT,
        TT
    }

    mapping(address account => mapping(BalanceType => uint256 amount)) private _balances;
    // mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

  
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * Queries the PT balance of an user/account (principal)
     */
    function balanceOf(address account) public view returns(uint) {
        return _balances[Type.PT][account];
        // return _balances[account];
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
        return _allowances[owner][spender];
    }

    
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
    function _getRatioYT(address account_, uint amount_) private pure returns(uint) {
        uint totalPT = _balances[Type.PT][account_];
        uint ratioPT = amount_.fullMulDiv(100 * 1e18, totalPT);
        
        // totalPTbal --- 100%
        // amount_ ------ x = % that amount represents of PT

        // (amount_ * 100) / totalPTbal

        uint totalYT = _balances[Type.YT][account_];
        return ratioPT.fullMulDiv(totalYT, 100 1e18); 

        // totalYTbal --- 100%
        //     x ------ ratioPTbal
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
            if (fromBalance == amount) {
                uint fromYT = _balances[Type.YT][from];

                _balances[Type.PT][from] = 0;
                _balances[Type.YT][from] = 0;

                _balances[Type.PT][to] += amount;
                _balances[Type.YT][to] += fromYT;

                _calculateNewTT(from, to);
            } else {
                //do this block with the info from below
            }

            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
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
