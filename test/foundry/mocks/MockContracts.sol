// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {MockStorage} from "./MockStorage.sol";
import {IAsset} from "../../../contracts/interfaces/IBalancer.sol";
import {ozIDiamond} from "../../../contracts/interfaces/ozIDiamond.sol";
import {IERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import {FixedPointMathLib} from "../../../contracts/libraries/FixedPointMathLib.sol";
import {AppStorage, Dir, Pair} from "../../../contracts/AppStorage.sol";
import {Helpers} from "../../../contracts/libraries/Helpers.sol";
import {IRocketTokenRETH} from "../../../contracts/interfaces/IRocketPool.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IUsingTellor} from "../../../contracts/interfaces/IUsingTellor.sol";
import {IERC20Permit} from "../../../contracts/interfaces/IERC20Permit.sol";
import {ozIToken} from "../../../contracts/interfaces/ozIToken.sol";
import {OZError23, OZError14} from "../../../contracts/Errors.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {OracleLibrary} from "../../../contracts/libraries/oracle/OracleLibrary.sol";
import {FixedPointMathRayLib, RAY, TWO} from "../../../contracts/libraries/FixedPointMathRayLib.sol";

import "forge-std/console.sol";


/**
 * Has the rETH-ETH price before staking rewards accrual +
 * how to get historical rETH-ETH price
 */
contract RethLinkFeed is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(18446744073709551854),
            int(rETHPreAccrual),
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }

    function getRoundData(uint80 roundId_) external pure returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        int price;

        if (roundId_ == 18446744073709551853) price = 1085995250282916400;
        if (roundId_ == 0) price = 1086486906594931900;

        return (
            uint80(1),
            price,
            1,
            1,
            uint80(1)
        );
    }
}


//Has the rETH-ETH price after staking rewards accrual
contract RethLinkFeedAccrued is MockStorage {
    function latestRoundData() external view returns(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            uint80(2),
            int(rETHPostAccrual),
            block.timestamp,
            block.timestamp,
            uint80(1)
        );
    }
}



//Has current ETH-USD price
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


/**
 * Simulates swaps with accurate (and simulated) price feeds for every pair,
 * disregarding liquidity unbalances, among other liquidity factors, in the 
 * output of amount of tokens out.
 */
contract SwapRouterMock is MockStorage {
    using FixedPointMathLib for *;

    ozIDiamond immutable OZ;

    constructor(address ozDiamond_) {
        OZ = ozIDiamond(ozDiamond_);
    }

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
    ) external payable returns (uint) {
        uint amountOut;
        uint decimals = USDC(params.tokenIn) ? 1e12 : 1; 
        uint decimals2 = USDC(params.tokenIn) ? 1e12 : 1; 

        console.log('params.tokenIn: ', params.tokenIn);

        if (USDC(params.tokenIn) || params.tokenIn == DAI) {
            console.log('here');
            amountOut = (params.amountIn * decimals).mulDivDown(1e18, OZ.ETH_USD());
        }
    
        if (params.tokenIn == WETH) {
            amountOut = (params.amountIn.mulDivDown(OZ.ETH_USD(), 1 ether)) / decimals2;   
            IERC20(params.tokenOut).transfer(params.recipient, amountOut);

            console.log('amountOut1: ', amountOut);

            return amountOut;
        }
        
        IERC20(params.tokenIn).transferFrom(msg.sender, address(1), params.amountIn);
        
        if (IERC20(params.tokenOut).balanceOf(address(this)) / 1e18 != 0) {
            IERC20(params.tokenOut).transfer(address(OZ), amountOut);
        }

        if (params.amountIn == 33000000) {
            console.log('amountOut2: ', amountOut);
            return amountOut;
        }

        console.log('amountOut3: ', amountOut);
        
        return amountOut;
    }
}


//Same as above.
contract VaultMock {

    using FixedPointMathLib for *;
    using FixedPointMathRayLib for *;

    ozIDiamond immutable OZ;

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

    constructor(address ozDiamond_) {
        OZ = ozIDiamond(ozDiamond_);
    }


    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint) {
        uint amountOut;

        console.log(1);
        console.log('singleSwap.amount in mock swap: ', singleSwap.amount);
        IERC20(address(singleSwap.assetIn)).transferFrom(address(OZ), address(1), singleSwap.amount);
        console.log(2);

        if (singleSwap.amount == 19673291323457014) 
        { 
            uint wethIn = 19673291323457014;
            amountOut =  wethIn.mulDivDown(1e18, OZ.rETH_ETH());
        } 

        if (singleSwap.amount == 18107251181805252) { 
            uint rETHin = 18107251181805252;
            amountOut = ((rETHin.ray())
                .mulDivRay(OZ.getUniPrice(0, Dir.UP).ray(), RAY ^ TWO))
                .unray();
        }

        console.log(1);
        IERC20(address(singleSwap.assetOut)).transfer(address(OZ), amountOut);
        console.log(2);
        console.log('amountOut in mock swap: ', amountOut);
        //<------- here *****
        
        emit DeadVars(funds, limit, deadline);

        return amountOut;
    }
}


contract MockOzOraclePreAccrual {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    

    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    
    //Remove complexity of this formula to make the test easier to run
    function rETH_ETH() public pure returns(uint) {
        return getUniPrice(0, Dir.UP) / 1e9;
    }

    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether;
    }

    function ETH_USD() public view returns(uint) { 
        (bool success, uint price) = _useLinkInterface(s.ethUsdChainlink, true);
        return success ? price : _callFallbackOracle(s.WETH);  
    }

    function getUniPrice(uint tokenPair_, Dir side_) public pure returns(uint) {
        uint amountOut;

        if (side_ == Dir.UP) {
            amountOut = 1086486906594931900766884076;
        } else if (side_ == Dir.DOWN) {
            amountOut = 1085995250282916400766884076;
        } else {
            return tokenPair_;
        }
    
        return amountOut;
    }

    //--------------

    function _triagePair(uint index_) private view returns(address, address, uint24) {
        Pair memory p = s.tokenPairs[index_];
        return (p.base, p.quote, p.fee);
    }

    function _callFallbackOracle(address baseToken_) private view returns(uint) {
        if (baseToken_ == s.WETH) {
            uint uniPrice = getUniPrice(2, Dir.UP);
            (bool success, uint tellorPrice) = getOracleBackUp1();
            (bool success2, uint redPrice) = getOracleBackUp2();

            if (success && success2) {
                return Helpers.getMedium(uniPrice, tellorPrice, redPrice);
            } else {
                return uniPrice;
            }
        } else if (baseToken_ == s.rETH) {
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return uniPrice01.getMedium(protocolPrice);
        }
        revert OZError23(baseToken_);
    }


    function getOracleBackUp1() public view returns(bool, uint) { 
        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth","usd")));

        (bool success, bytes memory value, uint timestamp) = 
            IUsingTellor(s.tellorOracle).getDataBefore(queryId, block.timestamp - DISPUTE_BUFFER);

        if (!success || block.timestamp - timestamp > TIMEOUT_EXTENDED) return (false, 0);

        return (true, abi.decode(value, (uint)));
    }

    //RedStone
    function getOracleBackUp2() public view returns(bool, uint) {
        (bool success, uint weETH_ETH) = _useLinkInterface(s.weETHETHredStone, false);
        (bool success2, uint weETH_USD) = _useLinkInterface(s.weETHUSDredStone, false);

        if (success && success2) {
            uint price = (1 ether ** 2 / weETH_ETH).mulDivDown(weETH_USD, 1 ether);
            return (true, price);
        } else {
            return (false, 0);
        }
    }

    function chargeOZLfee() external returns(bool) { 
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this)); 
        uint totalAssets;

        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i].ozToken).totalAssets();
        }

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        (uint assetsInETH, uint rEthInETH) = _calculateValuesInETH(totalAssets, amountReth);
        int totalRewards = int(rEthInETH) - int(assetsInETH); 

        if (totalRewards <= 0) return false;
        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;
        _getFeeAndForward(totalRewards, currentRewards);      

        return true;
    }

    function _getAdminFee(uint grossFees_) private returns(uint) {
        uint adminFee = uint(s.adminFee).mulDivDown(grossFees_, 10_000); 
        IERC20Permit(s.rETH).transfer(s.adminFeeRecipient, adminFee);

        return grossFees_ - adminFee;
    }


    function _calculateValuesInETH(uint assets_, uint amountReth_) private view returns(uint, uint) {
        uint assetsInETH = ((assets_ * 1e12) * 1 ether) / ETH_USD();
        uint valueInETH = (amountReth_ * rETH_ETH()) / 1 ether;

        return (assetsInETH, valueInETH);
    }

    function _getFeeAndForward(int totalRewards_, int currentRewards_) private returns(uint) {
        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards_), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards_);

        uint grossOzelFeesInRETH = (ozelFeesInETH * 1 ether) / rETH_ETH();
        uint netOzelFees = _getAdminFee(grossOzelFeesInRETH);
        IERC20Permit(s.rETH).transfer(s.ozlProxy, netOzelFees);
        
        return netOzelFees;
    }


    function _useLinkInterface(address priceFeed_, bool isLink_) private view returns(bool, uint) {
        uint timeout = TIMEOUT_LINK;
        uint BASE = 1e10;

        if (!isLink_) timeout = TIMEOUT_EXTENDED;
        if (priceFeed_ == s.rEthEthChainlink) BASE = 1;

        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();

        if (
            (roundId != 0 || _exemptRed(priceFeed_)) && 
            answer > 0 && 
            updatedAt != 0 && 
            updatedAt <= block.timestamp &&
            block.timestamp - updatedAt <= timeout
        ) {
            return (true, uint(answer) * BASE); 
        } else {
            return (false, 0); 
        }
    }


    function _exemptRed(address feed_) private view returns(bool) {
        return feed_ == s.weETHETHredStone;
    }
}


contract MockOzOraclePreAccrualNoDeviation {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    

    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    function rETH_ETH() public pure returns(uint) {
        return getUniPrice(0, Dir.UP) / 1e9;
    }

    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether;
    }

    function ETH_USD() public view returns(uint) { 
        (bool success, uint price) = _useLinkInterface(s.ethUsdChainlink, true);
        return success ? price : _callFallbackOracle(s.WETH);
    }

    function getUniPrice(uint tokenPair_, Dir side_) public pure returns(uint) {
        uint amountOut;

        if (side_ == Dir.UP) {
            amountOut = 1086486906594931900766884076;
        } else if (side_ == Dir.DOWN) {
            amountOut = 1085995250282916400766884076;
        } else {
            return tokenPair_;
        }
    
        return amountOut;
    }

    //--------------

    function _triagePair(uint index_) private view returns(address, address, uint24) {
        Pair memory p = s.tokenPairs[index_];
        return (p.base, p.quote, p.fee);
    }

    function _callFallbackOracle(address baseToken_) private view returns(uint) {
        if (baseToken_ == s.WETH) {
            uint uniPrice = getUniPrice(2, Dir.UP);
            (bool success, uint tellorPrice) = getOracleBackUp1();
            (bool success2, uint redPrice) = getOracleBackUp2();

            if (success && success2) {
                return Helpers.getMedium(uniPrice, tellorPrice, redPrice);
            } else {
                return uniPrice;
            }
        } else if (baseToken_ == s.rETH) {
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return uniPrice01.getMedium(protocolPrice);
        }
        revert OZError23(baseToken_);
    }


    function getOracleBackUp1() public view returns(bool, uint) { 
        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth","usd")));

        (bool success, bytes memory value, uint timestamp) = 
            IUsingTellor(s.tellorOracle).getDataBefore(queryId, block.timestamp - DISPUTE_BUFFER);

        if (!success || block.timestamp - timestamp > TIMEOUT_EXTENDED) return (false, 0);

        return (true, abi.decode(value, (uint)));
    }

    //RedStone
    function getOracleBackUp2() public view returns(bool, uint) {
        (bool success, uint weETH_ETH) = _useLinkInterface(s.weETHETHredStone, false);
        (bool success2, uint weETH_USD) = _useLinkInterface(s.weETHUSDredStone, false);

        if (success && success2) {
            uint price = (1 ether ** 2 / weETH_ETH).mulDivDown(weETH_USD, 1 ether);
            return (true, price);
        } else {
            return (false, 0);
        }
    }

    function chargeOZLfee() external returns(bool) { 
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this)); 
        uint totalAssets;

        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i].ozToken).totalAssets();
        }

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        (uint assetsInETH, uint rEthInETH) = _calculateValuesInETH(totalAssets, amountReth);
        int totalRewards = int(rEthInETH) - int(assetsInETH); 

        if (totalRewards <= 0) return false;
        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;
        _getFeeAndForward(totalRewards, currentRewards);      

        return true;
    }

    function _getAdminFee(uint grossFees_) private returns(uint) {
        uint adminFee = uint(s.adminFee).mulDivDown(grossFees_, 10_000); 
        IERC20Permit(s.rETH).transfer(s.adminFeeRecipient, adminFee);

        return grossFees_ - adminFee;
    }


    function _calculateValuesInETH(uint assets_, uint amountReth_) private view returns(uint, uint) {
        uint assetsInETH = ((assets_ * 1e12) * 1 ether) / ETH_USD();
        uint valueInETH = (amountReth_ * rETH_ETH()) / 1 ether;

        return (assetsInETH, valueInETH);
    }

    function _getFeeAndForward(int totalRewards_, int currentRewards_) private returns(uint) {
        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards_), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards_);

        uint grossOzelFeesInRETH = (ozelFeesInETH * 1 ether) / rETH_ETH();
        uint netOzelFees = _getAdminFee(grossOzelFeesInRETH);
        IERC20Permit(s.rETH).transfer(s.ozlProxy, netOzelFees);
        
        return netOzelFees;
    }


    function _useLinkInterface(address priceFeed_, bool isLink_) private view returns(bool, uint) {
        uint timeout = TIMEOUT_LINK;
        uint BASE = 1e10;

        if (!isLink_) timeout = TIMEOUT_EXTENDED;
        if (priceFeed_ == s.rEthEthChainlink) BASE = 1;

        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();

        if (
            (roundId != 0 || _exemptRed(priceFeed_)) && 
            answer > 0 && 
            updatedAt != 0 && 
            updatedAt <= block.timestamp &&
            block.timestamp - updatedAt <= timeout
        ) {
            return (true, uint(answer) * BASE); 
        } else {
            return (false, 0); 
        }
    }


    function _exemptRed(address feed_) private view returns(bool) {
        return feed_ == s.weETHETHredStone;
    }
}


contract MockOzOraclePostAccrual {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    

    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    event APRcalculated(
        uint indexed currAPR,
        uint indexed prevAPR,
        uint currentRewardsUSD,
        uint totalAssets,
        uint deltaStamp
    );


    /**
    * Removed the rest of the function and just kep the call to the oracle because
    * the backup oracle is not needed for the tests with these mocks, and this way
    * it simplifies the setup of the tests where this is used.
    */
    function rETH_ETH() public view returns(uint) {
        return getUniPrice(0, Dir.UP) / 1e9;
    }

    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether;
    }

    function ETH_USD() public view returns(uint) {
        (bool success, uint price) = _useLinkInterface(s.ethUsdChainlink, true);
        return success ? price : _callFallbackOracle(s.WETH);
    }

    function getUniPrice(uint tokenPair_, Dir side_) public view returns(uint) {
        uint amountOut; 

        if (tokenPair_ != 2) {
            if (side_ == Dir.UP) {
                amountOut = 1139946382858729176766884076;
            } else if (side_ == Dir.DOWN) {
                amountOut = 1086486906594931900766884076;
            } else {
                return tokenPair_;
            }
        } else {
            (address token0, address token1, uint24 fee) = _triagePair(tokenPair_);

            address pool = IUniswapV3Factory(s.uniFactory).getPool(token0, token1, fee);

            uint32 secsAgo = side_ == Dir.UP ? 1800 : 86400;
            //^ check the values I used for calculatin past rewards
            //check for Dir.DOWN also

            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = secsAgo;
            secondsAgos[1] = 0;

            (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int24 tick = int24(tickCumulativesDelta / int32(secsAgo));
            
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secsAgo) != 0)) tick--;
            
            amountOut = OracleLibrary.getQuoteAtTick(
                tick, 1 ether, token0, token1
            );
        
            return amountOut * (token1 == s.WETH ? 1 : 1e12);
        }
    
        return amountOut;
    }

    //--------------

    function _triagePair(uint index_) private view returns(address, address, uint24) {
        Pair memory p = s.tokenPairs[index_];
        return (p.base, p.quote, p.fee);
    }

    function _callFallbackOracle(address baseToken_) private view returns(uint) {
        if (baseToken_ == s.WETH) {
            uint uniPrice = getUniPrice(2, Dir.UP);
            (bool success, uint tellorPrice) = getOracleBackUp1();
            (bool success2, uint redPrice) = getOracleBackUp2();

            if (success && success2) {
                return Helpers.getMedium(uniPrice, tellorPrice, redPrice);
            } else {
                return uniPrice;
            }
        } else if (baseToken_ == s.rETH) {
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return uniPrice01.getMedium(protocolPrice);
        }
        revert OZError23(baseToken_);
    }

    function getOracleBackUp1() public view returns(bool, uint) { 
        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth","usd")));

        (bool success, bytes memory value, uint timestamp) = 
            IUsingTellor(s.tellorOracle).getDataBefore(queryId, block.timestamp - DISPUTE_BUFFER);

        if (!success || block.timestamp - timestamp > TIMEOUT_EXTENDED) return (false, 0);

        return (true, abi.decode(value, (uint)));
    }

    //RedStone
    function getOracleBackUp2() public view returns(bool, uint) {
        (bool success, uint weETH_ETH) = _useLinkInterface(s.weETHETHredStone, false);
        (bool success2, uint weETH_USD) = _useLinkInterface(s.weETHUSDredStone, false);

        if (success && success2) {
            uint price = (1 ether ** 2 / weETH_ETH).mulDivDown(weETH_USD, 1 ether);
            return (true, price);
        } else {
            return (false, 0);
        }
    }


    function chargeOZLfee() external returns(bool) { 
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this)); 
        uint totalAssets;

        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i].ozToken).totalAssets();
        }

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        (uint assetsInETH, uint rEthInETH) = _calculateValuesInETH(totalAssets, amountReth);        
        int totalRewards = int(rEthInETH) - int(assetsInETH); 

        if (totalRewards <= 0) return false;
        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;
        _getFeeAndForward(totalRewards, currentRewards);     

        _setAPR(uint(currentRewards), totalAssets);

        return true;
    }

    function _setAPR(uint currentRewardsETH_, uint totalAssets_) private {
        s.prevAPR = s.currAPR;
        uint deltaStamp = block.timestamp - s.lastRewardStamp;
        uint oneYear = 31540000;

        uint currentRewardsUSD = currentRewardsETH_.mulDivDown(ETH_USD(), 1 ether);

        s.currAPR = ((currentRewardsUSD / totalAssets_) * (oneYear / deltaStamp) * 100) * 1e6;

        emit APRcalculated(
            s.currAPR,
            s.prevAPR,
            currentRewardsUSD,
            totalAssets_,
            deltaStamp
        );

        s.lastRewardStamp = block.timestamp;
    }

    function _getAdminFee(uint grossFees_) private returns(uint) {
        uint adminFee = uint(s.adminFee).mulDivDown(grossFees_, 10_000); 
        IERC20Permit(s.rETH).transfer(s.adminFeeRecipient, adminFee);

        return grossFees_ - adminFee;
    }

    function _getFeeAndForward(int totalRewards_, int currentRewards_) private returns(uint) {
        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards_), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards_);

        uint grossOzelFeesInRETH = (ozelFeesInETH * 1 ether) / rETH_ETH();
        uint netOzelFees = _getAdminFee(grossOzelFeesInRETH);
        IERC20Permit(s.rETH).transfer(s.ozlProxy, netOzelFees);
        
        return netOzelFees;
    }


    function _calculateValuesInETH(uint assets_, uint amountReth_) private view returns(uint, uint) {
        uint assetsInETH = ((assets_ * 1e12) * 1 ether) / ETH_USD();
        uint valueInETH = (amountReth_ * rETH_ETH()) / 1 ether;

        return (assetsInETH, valueInETH);
    }


    function _useLinkInterface(address priceFeed_, bool isLink_) private view returns(bool, uint) {
        uint timeout = TIMEOUT_LINK;
        uint BASE = 1e10;

        if (!isLink_) timeout = TIMEOUT_EXTENDED;
        if (priceFeed_ == s.rEthEthChainlink) BASE = 1;

        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();

        if (
            (roundId != 0 || _exemptRed(priceFeed_)) && 
            answer > 0 && 
            updatedAt != 0 && 
            updatedAt <= block.timestamp &&
            block.timestamp - updatedAt <= timeout
        ) {
            return (true, uint(answer) * BASE); 
        } else {
            return (false, 0); 
        }
    }


    function _exemptRed(address feed_) private view returns(bool) {
        return feed_ == s.weETHETHredStone;
    }
}

//Contract strimmed-lined for the functions affecting the calculation of the APR
contract MockOzOraclePostAccrualHigher {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    
    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    event APRcalculated(
        uint indexed currAPR,
        uint indexed prevAPR,
        uint currentRewardsUSD,
        uint totalAssets,
        uint deltaStamp
    );

    /**
    * Removed the rest of the function and just kep the call to the oracle because
    * the backup oracle is not needed for the tests with these mocks, and this way
    * it simplifies the setup of the tests where this is used.
    */
    function rETH_ETH() public view returns(uint) {
        return getUniPrice(0, Dir.UP) / 1e9;
    }

    function rETH_USD() public view returns(uint) { 
        return (rETH_ETH() * ETH_USD()) / 1 ether;
    }

    //Remove callFallbackOracle() to simplify test since it's not called
    function ETH_USD() public view returns(uint) {
        (,uint price) = _useLinkInterface(s.ethUsdChainlink, true);
        return price;
    }

    function getUniPrice(uint tokenPair_, Dir side_) public view returns(uint) {
        uint amountOut; 

        if (tokenPair_ != 2) {
            if (side_ == Dir.UP) {
                amountOut = 1149946382858729176766884076;
            } else if (side_ == Dir.DOWN) {
                amountOut = 1086486906594931900766884076;
            } else {
                return tokenPair_;
            }
        } else {
            (address token0, address token1, uint24 fee) = _triagePair(tokenPair_);

            address pool = IUniswapV3Factory(s.uniFactory).getPool(token0, token1, fee);

            uint32 secsAgo = side_ == Dir.UP ? 1800 : 86400;
            //^ check the values I used for calculatin past rewards
            //check for Dir.DOWN also

            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = secsAgo;
            secondsAgos[1] = 0;

            (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int24 tick = int24(tickCumulativesDelta / int32(secsAgo));
            
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int32(secsAgo) != 0)) tick--;
            
            amountOut = OracleLibrary.getQuoteAtTick(
                tick, 1 ether, token0, token1
            );
        
            return amountOut * (token1 == s.WETH ? 1 : 1e12);
        }
    
        return amountOut;
    }

    //--------------

    function _triagePair(uint index_) private view returns(address, address, uint24) {
        Pair memory p = s.tokenPairs[index_];
        return (p.base, p.quote, p.fee);
    }


    function chargeOZLfee() external returns(bool) { 
        uint amountReth = IERC20Permit(s.rETH).balanceOf(address(this)); 
        uint totalAssets;

        for (uint i=0; i < s.ozTokenRegistry.length; i++) {
            totalAssets += ozIToken(s.ozTokenRegistry[i].ozToken).totalAssets();
        }

        if (block.number <= s.rewards.lastBlock) revert OZError14(block.number);

        (uint assetsInETH, uint rEthInETH) = _calculateValuesInETH(totalAssets, amountReth);        
        int totalRewards = int(rEthInETH) - int(assetsInETH); 

        if (totalRewards <= 0) return false;
        int currentRewards = totalRewards - int(s.rewards.prevTotalRewards);

        if (currentRewards <= 0) return false;
        _getFeeAndForward(totalRewards, currentRewards);     

        _setAPR(uint(currentRewards), totalAssets);

        return true;
    }

    function _setAPR(uint currentRewardsETH_, uint totalAssets_) private {
        s.prevAPR = s.currAPR;
        uint deltaStamp = block.timestamp - s.lastRewardStamp;
        uint oneYear = 31540000;

        uint currentRewardsUSD = currentRewardsETH_.mulDivDown(ETH_USD(), 1 ether);

        s.currAPR = ((currentRewardsUSD / totalAssets_) * (oneYear / deltaStamp) * 100) * 1e6;

        emit APRcalculated(
            s.currAPR,
            s.prevAPR,
            currentRewardsUSD,
            totalAssets_,
            deltaStamp
        );

        s.lastRewardStamp = block.timestamp;
    }

    function _getAdminFee(uint grossFees_) private returns(uint) {
        uint adminFee = uint(s.adminFee).mulDivDown(grossFees_, 10_000); 
        IERC20Permit(s.rETH).transfer(s.adminFeeRecipient, adminFee);

        return grossFees_ - adminFee;
    }

    function _getFeeAndForward(int totalRewards_, int currentRewards_) private returns(uint) {
        uint ozelFeesInETH = uint(s.protocolFee).mulDivDown(uint(currentRewards_), 10_000);
        s.rewards.prevTotalRewards = uint(totalRewards_);

        uint grossOzelFeesInRETH = (ozelFeesInETH * 1 ether) / rETH_ETH();
        uint netOzelFees = _getAdminFee(grossOzelFeesInRETH);
        IERC20Permit(s.rETH).transfer(s.ozlProxy, netOzelFees);
        
        return netOzelFees;
    }


    function _calculateValuesInETH(uint assets_, uint amountReth_) private view returns(uint, uint) {
        uint assetsInETH = ((assets_ * 1e12) * 1 ether) / ETH_USD();
        uint rEthInETH = (amountReth_ * rETH_ETH()) / 1 ether;

        return (assetsInETH, rEthInETH);
    }

    //Edited
    function _useLinkInterface(address priceFeed_, bool isLink_) private view returns(bool, uint) {
        uint timeout = TIMEOUT_LINK;
        uint BASE = 1e10;

        if (!isLink_) timeout = TIMEOUT_EXTENDED;
        if (priceFeed_ == s.rEthEthChainlink) BASE = 1;

        (,int answer,,,) = AggregatorV3Interface(priceFeed_).latestRoundData();

        return (true, uint(answer) * BASE);
    }


    function _exemptRed(address feed_) private view returns(bool) {
        return feed_ == s.weETHETHredStone;
    }
}


contract MockOzOracleLink {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    

    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    function rETH_ETH() public view returns(uint) {
        (bool success, uint refPrice) = _useLinkInterface(s.rEthEthChainlink, true);
        uint mainPrice = getUniPrice(0, Dir.UP);

        if (mainPrice.checkDeviation(refPrice, s.deviation) && success) {
            return mainPrice / 1e9;
        } else {
            return _callFallbackOracle(s.rETH);
        }
    }

    function rETH_USD() public view returns(uint) {
        return (rETH_ETH() * ETH_USD()) / 1 ether;
    }

    function ETH_USD() public view returns(uint) {
        (bool success, uint price) = _useLinkInterface(s.ethUsdChainlink, true);
        return success ? price : _callFallbackOracle(s.WETH);  
    }

    function getUniPrice(uint tokenPair_, Dir side_) public view returns(uint) {
        uint price;
        
        (uint80 roundId, int answer,,,) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        price = uint(answer);

        if (side_ == Dir.DOWN) {
            (,int pastAnswer,,,) = AggregatorV3Interface(s.rEthEthChainlink).getRoundData(roundId - 1);
            price = uint(pastAnswer);
        }

        return price > 0 ? price : tokenPair_;
    }

    //--------------

    function _triagePair(uint index_) private view returns(address, address, uint24) {
        Pair memory p = s.tokenPairs[index_];
        return (p.base, p.quote, p.fee);
    }

    function _callFallbackOracle(address baseToken_) private view returns(uint) {
        if (baseToken_ == s.WETH) {
            uint uniPrice = getUniPrice(2, Dir.UP);
            (bool success, uint tellorPrice) = getOracleBackUp1();
            (bool success2, uint redPrice) = getOracleBackUp2();

            if (success && success2) {
                return Helpers.getMedium(uniPrice, tellorPrice, redPrice);
            } else {
                return uniPrice;
            }
        } else if (baseToken_ == s.rETH) {
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return uniPrice01.getMedium(protocolPrice);
        }
        revert OZError23(baseToken_);
    }

    function getOracleBackUp1() public view returns(bool, uint) { 
        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth","usd")));

        (bool success, bytes memory value, uint timestamp) = 
            IUsingTellor(s.tellorOracle).getDataBefore(queryId, block.timestamp - DISPUTE_BUFFER);

        if (!success || block.timestamp - timestamp > TIMEOUT_EXTENDED) return (false, 0);

        return (true, abi.decode(value, (uint)));
    }

    //RedStone
    function getOracleBackUp2() public view returns(bool, uint) {
        (bool success, uint weETH_ETH) = _useLinkInterface(s.weETHETHredStone, false);
        (bool success2, uint weETH_USD) = _useLinkInterface(s.weETHUSDredStone, false);

        if (success && success2) {
            uint price = (1 ether ** 2 / weETH_ETH).mulDivDown(weETH_USD, 1 ether);
            return (true, price);
        } else {
            return (false, 0);
        }
    }


    function _useLinkInterface(address priceFeed_, bool isLink_) private view returns(bool, uint) {
        uint timeout = TIMEOUT_LINK;
        uint BASE = 1e10;

        if (!isLink_) timeout = TIMEOUT_EXTENDED;
        if (priceFeed_ == s.rEthEthChainlink) BASE = 1;

        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();

        if (
            (roundId != 0 || _exemptRed(priceFeed_)) && 
            answer > 0 && 
            updatedAt != 0 && 
            updatedAt <= block.timestamp &&
            block.timestamp - updatedAt <= timeout
        ) {
            return (true, uint(answer) * BASE); 
        } else {
            return (false, 0); 
        }
    }


    function _exemptRed(address feed_) private view returns(bool) {
        return feed_ == s.weETHETHredStone;
    }
}


