// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract ozToken is ERC20 { //add AccessControl here

    uint private constant _BASE = 1e18;

    uint public rewardMultiplier;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    constructor(
        string memory name_, 
        string memory symbol_
    ) ERC20(name_, symbol_) {

    }

    function convertToTokens(uint shares_) public view returns(uint) {
        return (shares_ * rewardMultiplier) * _BASE;
    }


    
    /**
        Multiplier functions
     */
    function addRewardMultiplier(uint256 _rewardMultiplierIncrement) external { //onlyRole(ORACLE_ROLE)
        if (_rewardMultiplierIncrement == 0) {
            // revert USDMInvalidRewardMultiplier(_rewardMultiplierIncrement);
            revert();
        }

        _setRewardMultiplier(rewardMultiplier + _rewardMultiplierIncrement);
    }


    function _setRewardMultiplier(uint256 _rewardMultiplier) private {
        if (_rewardMultiplier < _BASE) {
            // revert USDMInvalidRewardMultiplier(_rewardMultiplier);
            revert();
        }

        rewardMultiplier = _rewardMultiplier;

        // emit RewardMultiplier(rewardMultiplier);
    }


}