// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;



interface IfrxETHMinter {
    function depositEtherPaused() external view returns(bool);
    function submitAndDeposit(address recipient) external payable returns (uint256 shares);
}