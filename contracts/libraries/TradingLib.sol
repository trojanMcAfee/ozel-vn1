pragma solidity 0.8.21;


import {IVault, IAsset, IPool, IQueries} from "../interfaces/IBalancer.sol";
import "../Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


library TradingLib {


    function useOZL(
        address tokenIn_, 
        address tokenOut_, 
        address sender_,
        address receiver_,
        uint amountIn_,
        uint minAmountOutOffchain_
    ) internal {
        uint amountOut;
        
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: IPool(0x1E19CF2D73a72Ef1332C882F20534B6519Be0276).getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(tokenIn_),
            assetOut: IAsset(tokenOut_),
            amount: amountIn_,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: sender_,
            fromInternalBalance: false, 
            recipient: payable(receiver_),
            toInternalBalance: false
        });
        
        try IQueries(0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5).querySwap(singleSwap, funds) returns(uint minOutOnchain) {
            uint minOut = minAmountOutOffchain_ > minOutOnchain ? minAmountOutOffchain_ : minOutOnchain;

            SafeERC20.safeApprove(IERC20(tokenIn_), 0xBA12222222228d8Ba445958a75a0704d566BF2C8, singleSwap.amount);
            amountOut = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8).swap(singleSwap, funds, minOut, block.timestamp);
        } catch Error(string memory reason) {
            revert OZError10(reason);
        }
        
        if (amountOut == 0) revert OZError02();
    }

}