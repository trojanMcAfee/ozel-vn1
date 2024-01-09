pragma solidity 0.8.21;


import {IVault, IAsset, IPool, IQueries} from "../interfaces/IBalancer.sol";
import "../Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TradingPackage} from "../AppStorage.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


library TradingLib {

    enum Action {
        OZL_OUT,
        OZ_IN,
        OZ_OUT
    }

    function _checkPauseAndSwap(
        // address tokenIn_, 
        // address tokenOut_, 
        TradingPackage memory p,
        address tokenOut_,
        address receiver_,
        uint amountIn_,
        uint minAmountOut_,
        Action type_
    ) private returns(uint amountOut) {
        // uint amountOut;
        address tokenIn;
        address tokenOut;

        if (type_ == Action.OZL_OUT) {
            tokenIn = p.rETH;
            tokenOut = p.WETH;
        } 

        (bool paused,,) = IPool(p.rEthWethPoolBalancer).getPausedState(); 

        if (paused) {
            _swapUni(
                tokenIn,
                tokenOut,
                address(this),
                p.swapRouterUni,
                p.uniFee,
                amountIn_,
                minAmountOut_
            );
        } else {
            amountOut = _swapBalancer(
                tokenIn,
                tokenOut,
                p.rEthWethPoolBalancer,
                p.queriesBalancer,
                p.vaultBalancer,
                amountIn_,
                minAmountOut_
            );
        }

        amountOut = _swapUni(
            p.WETH,
            tokenOut_,
            receiver_,
            p.swapRouterUni,
            p.uniFee,
            amountOut,
            minAmountOut_ //diff from swapBal, but for now it's at 0
        );
    }

    function useOZL(
        TradingPackage memory p,
        address tokenOut_,
        address receiver_,
        // address sender_,
        uint amountIn_,
        uint minAmountOut_
    ) internal {
        _checkPauseAndSwap(
            p,
            tokenOut_,
            receiver_,
            amountIn_,
            minAmountOut_,
            Action.OZL_OUT
        );
    }


    function _swapUni(
        address tokenIn_,
        address tokenOut_,
        address receiver_,
        address router_,
        uint24 poolFee_,
        uint amountIn_, 
        uint minAmountOut_
    ) private returns(uint) {
        SafeERC20.safeApprove(IERC20(tokenIn_), router_, amountIn_);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({ 
                tokenIn: tokenIn_,
                tokenOut: tokenOut_, 
                fee: poolFee_, 
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: 0, //minAmountOut_.formatMinOut(tokenOut_)
                sqrtPriceLimitX96: 0
            });

        try ISwapRouter(router_).exactInputSingle(params) returns(uint amountOut) { 
            return amountOut;
        } catch Error(string memory reason) {
            revert OZError01(reason);
        }
    }


    function _swapBalancer(
        address tokenIn_, 
        address tokenOut_, 
        address pool_,
        address queries_,
        address vault_,
        uint amountIn_,
        uint minAmountOutOffchain_
    ) private returns(uint amountOut) {
        // uint amountOut;
        
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: IPool(pool_).getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(tokenIn_),
            assetOut: IAsset(tokenOut_),
            amount: amountIn_,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false, 
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        
        try IQueries(queries_).querySwap(singleSwap, funds) returns(uint minOutOnchain) {
            uint minOut = minAmountOutOffchain_ > minOutOnchain ? minAmountOutOffchain_ : minOutOnchain;

            SafeERC20.safeApprove(IERC20(tokenIn_), vault_, singleSwap.amount);
            amountOut = IVault(vault_).swap(singleSwap, funds, minOut, block.timestamp);
        } catch Error(string memory reason) {
            revert OZError10(reason);
        }
        
        if (amountOut == 0) revert OZError02();
    }



    // function useOZL2(
    //     // address tokenIn_, 
    //     // address tokenOut_, 
    //     TradingPackage memory p,
    //     address sender_,
    //     // address receiver_,
    //     uint amountIn_,
    //     uint minAmountOutOffchain_
    // ) internal {
    //     uint amountOut;
        
    //     IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
    //         poolId: IPool(0x1E19CF2D73a72Ef1332C882F20534B6519Be0276).getPoolId(),
    //         kind: IVault.SwapKind.GIVEN_IN,
    //         assetIn: IAsset(tokenIn_),
    //         assetOut: IAsset(tokenOut_),
    //         amount: amountIn_,
    //         userData: new bytes(0)
    //     });

    //     IVault.FundManagement memory funds = IVault.FundManagement({
    //         sender: sender_,
    //         fromInternalBalance: false, 
    //         recipient: payable(receiver_),
    //         toInternalBalance: false
    //     });
        
    //     try IQueries(0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5).querySwap(singleSwap, funds) returns(uint minOutOnchain) {
    //         uint minOut = minAmountOutOffchain_ > minOutOnchain ? minAmountOutOffchain_ : minOutOnchain;

    //         SafeERC20.safeApprove(IERC20(tokenIn_), 0xBA12222222228d8Ba445958a75a0704d566BF2C8, singleSwap.amount);
    //         amountOut = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8).swap(singleSwap, funds, minOut, block.timestamp);
    //     } catch Error(string memory reason) {
    //         revert OZError10(reason);
    //     }
        
    //     if (amountOut == 0) revert OZError02();
    // }

}