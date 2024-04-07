// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {MockStorage} from "../MockStorage.sol";
import {IAsset} from "../../../../contracts/interfaces/IBalancer.sol";
import {ozIDiamond} from "../../../../contracts/interfaces/ozIDiamond.sol";
import {IERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import {FixedPointMathLib} from "../../../../contracts/libraries/FixedPointMathLib.sol";
import {AppStorage, Dir, Pair} from "../../../../contracts/AppStorage.sol";
import {Helpers} from "../../../../contracts/libraries/Helpers.sol";
import {IRocketTokenRETH} from "../../../../contracts/interfaces/IRocketPool.sol";
import "../../../../contracts/Errors.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IUsingTellor} from "../../../../contracts/interfaces/IUsingTellor.sol";

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


contract RethPreAccrualTWAP {

    function observe(uint32[] calldata secondsAgos) external view returns(
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s
    ) {
        secondsPerLiquidityCumulativeX128s = new uint160[](1);
        secondsPerLiquidityCumulativeX128s[0] = 2;
        tickCumulatives = new int56[](2);


        //When Dir.DOWN was higher than Dir.UP using orignal values, the difference between all balances
        //between all balances and the totalSupply() was 61 wei. Check this.
        //Check also if I decrease the difference by lowering Dir.DOWN even more, if the difference on 
        //totalSupply() increases from just 1.
        if (secondsAgos[0] == 1800) {
            tickCumulatives[0] = 27639974418;
            tickCumulatives[1] = 27641473818;
        } else if (secondsAgos[0] == 86400) {
            tickCumulatives[0] = 24812246673; //27569162970(org) / 24812246673(10%)
            tickCumulatives[1] = 24877326437; //27641473818(org) / 24877326437(10%)
        }

        return (tickCumulatives, secondsPerLiquidityCumulativeX128s);
    }
}


contract RethAccruedTWAP {

    function observe(uint32[] calldata secondsAgos) external view returns(
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s
    ) { 
        secondsPerLiquidityCumulativeX128s = new uint160[](1);
        secondsPerLiquidityCumulativeX128s[0] = 2;
        tickCumulatives = new int56[](2);

        // tickCumulatives[0] = 48369955231;
        // tickCumulatives[1] = 48372579181;

        if (secondsAgos[0] == 1800) {
            tickCumulatives[0] = 47911131656; //30403971859
            tickCumulatives[1] = 47913730716; //30405621199
        } else if (secondsAgos[0] == 86400) {
            tickCumulatives[0] = 27639974418; //these are from pre-accrual Dir.UP
            tickCumulatives[1] = 27641473818; 
        }

        //figuring out why totalSupply is off from total balances
        //trying a next example with accurate accrual (6%)

        return (tickCumulatives, secondsPerLiquidityCumulativeX128s);
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

        if (params.tokenIn == USDC) amountOut = (params.amountIn * 1e12).mulDivDown(1e18, OZ.ETH_USD());
    
        if (params.tokenIn == WETH) {
            amountOut = (params.amountIn.mulDivDown(OZ.ETH_USD(), 1 ether)) / 1e12;   
            IERC20(params.tokenOut).transfer(params.recipient, amountOut);
            return amountOut;
        }
        
        IERC20(params.tokenIn).transferFrom(msg.sender, address(1), params.amountIn);
        
        if (IERC20(params.tokenOut).balanceOf(address(this)) / 1e18 != 0) {
            IERC20(params.tokenOut).transfer(address(OZ), amountOut);
        }

        if (params.amountIn == 33000000) return amountOut;
        
        return amountOut;
    }
}


//Same as above.
contract VaultMock {

    using FixedPointMathLib for *;


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
        // ozIDiamond OZ = ozIDiamond(0x92a6649Fdcc044DA968d94202465578a9371C7b1);
        uint amountOut;

        IERC20(address(singleSwap.assetIn)).transferFrom(address(OZ), address(1), singleSwap.amount);

        if (singleSwap.amount == 19673291323457014) 
        { 
            uint wethIn = 19673291323457014;
            amountOut =  wethIn.mulDivDown(1 ether, OZ.rETH_ETH());
        } 

        if (singleSwap.amount == 18107251181805252) { 
            uint rETHin = 18107251181805252;
            amountOut = rETHin.mulDivDown(OZ.rETH_ETH(), 1e18);
        }

        IERC20(address(singleSwap.assetOut)).transfer(address(OZ), amountOut);
        
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

    function rETH_ETH() public view returns(uint) {
        return getUniPrice(0, Dir.UP);
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

        if (side_ == Dir.UP) {
            amountOut = 1086486906594931900;
        } else if (side_ == Dir.DOWN) {
            amountOut = 1085995250282916400;
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
            uint uniPrice05 = getUniPrice(0, Dir.UP);
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return Helpers.getMedium(uniPrice05, uniPrice01, protocolPrice);
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


contract MockOzOraclePostAccrual {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    

    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    function rETH_ETH() public view returns(uint) {
        return getUniPrice(0, Dir.UP);
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

        if (side_ == Dir.UP) {
            amountOut = 1129946382858729176;
        } else if (side_ == Dir.DOWN) {
            amountOut = 1086486906594931900;
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
            uint uniPrice05 = getUniPrice(0, Dir.UP);
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return Helpers.getMedium(uniPrice05, uniPrice01, protocolPrice);
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


contract MockOzOracleLink {
    AppStorage private s;

    using Helpers for *;
    using FixedPointMathLib for *;
    

    uint constant public DISPUTE_BUFFER = 15 minutes; //add this also to AppStorage
    uint constant public TIMEOUT_EXTENDED = 24 hours;
    uint constant public TIMEOUT_LINK = 4 hours;

    function rETH_ETH() public view returns(uint) {
        return getUniPrice(0, Dir.UP);
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
        
        (
            uint80 roundId,
            int answer,,
            uint updatedAt,
        ) = AggregatorV3Interface(s.rEthEthChainlink).latestRoundData();
        price = uint(answer);

        if (side_ == Dir.DOWN) {
            (,int pastAnswer,,,) = AggregatorV3Interface(s.rEthEthChainlink).getRoundData(roundId - 1);
            price = uint(pastAnswer);
        }

        return price;
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
            uint uniPrice05 = getUniPrice(0, Dir.UP);
            uint uniPrice01 = getUniPrice(1, Dir.UP);
            uint protocolPrice = IRocketTokenRETH(s.rETH).getExchangeRate();

            return Helpers.getMedium(uniPrice05, uniPrice01, protocolPrice);
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


