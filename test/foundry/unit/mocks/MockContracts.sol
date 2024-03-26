// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {MockStorage} from "../MockStorage.sol";
import {IAsset} from "../../../../contracts/interfaces/IBalancer.sol";
import {IERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";


contract RethLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(rETHPreAccrual),
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}


contract EthLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(currentPriceETH) / 1e10,
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}


contract SwapRouterMock {
    event DeadVar(ExactInputSingleParams params);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut) {
        emit DeadVar(params);
        
        address ozDiamond = 0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240;
        uint amountOut = 19662547189176713;

        IERC20(params.tokenIn).transferFrom(msg.sender, address(1), params.amountIn);
        IERC20(params.tokenOut).transfer(ozDiamond, amountOut);

        if (params.amountIn == 33000000) return amountOut;
        if (params.amountIn == 19646820040369690) return 32940641;
    }
}


contract VaultMock {
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    event DeadVars(FundManagement funds, uint limit, uint deadline);

    // function getPoolId() public view returns (bytes32) {
    //     return 0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112;
    // }


    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256) {
        address ozDiamond = 0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240; //0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240

        console.log('allow - vault: ', IERC20(address(singleSwap.assetIn)).allowance(msg.sender, address(this)));
        console.log('singleSwap.amount: ', singleSwap.amount);
        console.log('address(singleSwap.assetIn): ', address(singleSwap.assetIn));
        console.log('bal tokenIn - sender: ', IERC20(address(singleSwap.assetIn)).balanceOf(msg.sender));
        console.log('bal tokenIn - this: ', IERC20(address(singleSwap.assetIn)).balanceOf(address(this)));
        console.log('bal tokenIn - ozDiamond: ', IERC20(address(singleSwap.assetIn)).balanceOf(ozDiamond));
        console.log('owner of coins - sender: ', msg.sender);
        console.log('owner of coins - this: ', address(this));

        //spender -> mockVault
        //owner -> ozDiamond
        //msg.sender -> 
        //address(this) -> mockVault

        ERC20(address(singleSwap.assetIn)).transferFrom(ozDiamond, address(1), singleSwap.amount);
        console.log(2);
        
        if (singleSwap.amount == 19662547189176713) return 18081415515835888;
        if (singleSwap.amount == 19662545835237478) return 18081413499483890;
        if (singleSwap.amount == 18081414507659889) return 19646820040369690;

        emit DeadVars(funds, limit, deadline);
    }
}