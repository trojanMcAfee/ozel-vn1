pragma solidity 0.8.21;

/**
* Standard ERC20 Errors
* @dev See https://eips.ethereum.org/EIPS/eip-6093
*/
// error ERC20InsufficientBalance(address sender, uint256 shares, uint256 sharesNeeded);
// error ERC20InvalidSender(address sender);
// error ERC20InvalidReceiver(address receiver);
// error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
// error ERC20InvalidApprover(address approver);
// error ERC20InvalidSpender(address spender);
// // ERC2612 Errors
// error ERC2612ExpiredDeadline(uint256 deadline, uint256 blockTimestamp);
// error ERC2612InvalidSignature(address owner, address spender);
// // USDM Errors
// error USDMInvalidMintReceiver(address receiver);
// error USDMInvalidBurnSender(address sender);
// error USDMInsufficientBurnBalance(address sender, uint256 shares, uint256 sharesNeeded);
// error USDMInvalidRewardMultiplier(uint256 rewardMultiplier);
// error USDMBlockedSender(address sender);
// error USDMInvalidBlockedAccount(address account);
// error USDMPausedTransfers();

//--- My Errors

error OZError01(string errorMsg); //_swapUni - error string from uniswap
error OZError02(); //_swapBalancer - amount was 0
error OZError10(string errorCode); //_swapBalancer
error OZError11(address token); //createOzToken - can't be 0 address
error OZError12(address token); //createOzToken - TokenAlreadyInRegistry
error OZError13(address caller); //onlyOzToken - Not authorized
error OZError14(uint blockNumber); //_applyFee - blockNum is equal or less than last rewards update

//--- ozToken errors
error OZError03(); //decreaseAllowance - decreased allowance below zero
error OZError04(address from, address to); //_approve / _transfer - can't be zero address
error OZError05(uint amount); //_spendAllowance - insufficient allowance
error OZError06(address sender, uint accountShares, uint shares); //redeem - insufficient redeem balance
error OZError07(address from, uint fromShares, uint shares); //_transfer - insufficient sender balance
error OZError08(uint deadline, uint blockTimestamp); //permit - ERC2612ExpiredDeadline
error OZError09(address owner, address spender); //permit - ERC2612InvalidSignature



// 1st round - blockNum -> 1
// 1 > 0
// end -> 0
// start -> 1

// 2nd round - blockNum -> 2
// 2 > 1
// end -> 1
// start -> 2

// 3rd round - blockNumb -> 3
// 3 > 2
// end -> 2
// start -> 3
