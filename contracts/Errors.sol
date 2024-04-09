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
error OZError02(); //_swapBalancer - amountOut was 0
error OZError10(string errorCode); //_swapBalancer --> this error might not exist anymore (replaced by OZError21())
error OZError11(address token); //createOzToken - can't be 0 address
error OZError12(address token); //createOzToken - TokenAlreadyInRegistry
error OZError13(address caller); //onlyOzToken & changeAdminFeeRecipient - Not authorized
error OZError14(uint blockNumber); //_applyFee - blockNum is equal or less than last rewards update

//--- ozToken errors
error OZError03(); //decreaseAllowance - decreased allowance below zero
error OZError04(address from, address to); //_approve / _transfer - can't be zero address
error OZError05(uint amount); //_spendAllowance - insufficient allowance
error OZError06(address sender, uint accountShares, uint shares); //redeem - insufficient redeem balance
error OZError07(address from, uint fromShares, uint shares); //ozToken.sol / _transfer - insufficient sender balance
error OZError08(uint deadline, uint blockTimestamp); //permit - ERC2612ExpiredDeadline
error OZError09(address owner, address spender); //permit - ERC2612InvalidSignature
error OZError35(uint ozAmountIn); //redeem - ozAmountIn is less than allowed

//--- OZLrewards errors
error OZError15(); //setRewardsDuration - rewards duration not finished
error OZError16(); //notifyRewardAmount - reward rate = 0
error OZError17(); //notifyRewardAmount - reward amount > balance

//----- OZL errors
error OZError18(address tokenOut); //redeem - not valid token out
error OZError19(uint amount); //redeem - redeem amount is less than minAmountOut

//--- More my errors
error OZError20(); //_swapBalancer - not enough slippage (could be the same as OZError19 - check)
error OZError21(string reason); //_swapBalancer - other balancer failure reason besides slippage
error OZError22(string reason); // mint/redeem - useUnderlying/userOzTokens - catches internal exceptions like SafeERC20s. Most likely an STF error due to token allowace
error OZError24(); // _setImplementation - implementation is not a contract
error OZError25(address implementation); //_setBeacon / ozERC1967Upgrade.sol - beacon implementation is not a contract
error OZError26(address newBeacon); //_setBeacon / ozERC1967Upgrade.sol - new beacon is not a contract
error OZError33(address caller); // multiple ozCut.sol funcs / Modifiers.sol / not owner
error OZError34(uint amount); //allocate / OZL.sol - amount greater than pending to allocate

//Oracle errors
error OZError23(address baseToken); //_callFallbackOracle - wrong baseToken_

//Pause errors
error OZError27(uint index); //isPaused / Modifiers.sol - the index of the section that's paused
error OZError28(bool state); //pause / ozCut.sol - contract is already in state
error OZError29(); //pause / ozCut.sol - can't set the pause flag directly
error OZError30(); //pause / ozCut.sol - switch is disabled. System can't be paused. 
error OZError31(address facet); //addPauseContract - ozCut.sol - facet not found in ozDiamond
error OZError32(); //addPauseContract / ozCut.sol - cant add address(0) as a pause facet
