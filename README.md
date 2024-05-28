# Stablecoin wrapper for encapsulating the Ethereum Staking rate

## Purpose and Current State
This project was intented to be a rebranding of [Ozel](https://github.com/trojanMcAfee/ozel), as a wrapper for ERC20 stablecoins pegged to 1 USD.

Its developement was stopped due to finding an edge case that proved, after testing, to have no viable onchain solution at the moment, so further efforts had to be halted until the necessary technology and/or protocolos are created beforehand. 

This edge case will be explained in the lines to follow. 

## Vision
The wrapper is a system of contracts where a user would send a pre-authorized stablecoin, such as USDC, USDT or DAI, as input, and at the other end, get, as output, a 1:1 rebasing representation of their token (called ozDAI for DAI), plus the USD value (at current market price) of the Ethereum Staking Rewards equivalent to the amount of ETH that could have been purchased with the USD-stablecoin input sent to the contracts. For example:

- Alice sends 1000 USDC to the ozUSDC contract
   - The average price of ETHUSD for a year is 1500.
- Alice gets 1000.35 ozUSDC as the minting output.
   - The Ethereum Staking Rate is a constant of 3%
- After a year, Alice ends up with ~1030 ozUSDC that she can redeem at any time for 1030 USDC.

Besides the ERC20 wrappers, the system produces another token called `OZL`, which is given to users by the amount of stablecoin volume they bring and the amount of time they keep this stablecoin volume within the system. 

The protocol charges a fee of 10% of the Staking Rewards gained as a whole, and distributes them to the holders of the OZL token.

## Business & Logical Specs
Under the hood, the system grabs the stablecoin being sent to it (USDC, USDT or DAI), and spot-buys rETH with it through two swaps that happen in Balancer's rETHETH pool and Uniswap V3's Router. Then, it gives the user a 1:1 representation of their stablecoin which accrues the Ethereum Staking rewards, which get forwarded at the current ETHUSD market price at the moment that the rebase happens. 

The reason why a Balancer pool was used and not everything through Uniswap is because Balancer's rETHETH pool is the official pool for rETH (even mentioned in their docs), so it's the one with the most liquidity in this asset pair. 

Native rETH minting is also used, but since this option is not always available, recurring to swaps would be an often path for the majority of users. 

## Technical Specifications 
- It uses the Diamond Proxy pattern ([EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)) from scratch, as a new project. 
- The ozTokens design (ozERC20 and wrapped ozERC20) is comprised of:
  - Proxy:
    - Slightly modified version of [Open Zeppelin's Beacon Proxy](https://docs.openzeppelin.com/contracts/3.x/api/proxy#BeaconProxy) so it could fit the two-tokens design (oz/wozERC20)
  - Implementations:
    - These follow the model of Lido, where they have stETH as the main rebasing token, and wstETH as the wrapper token designed with shares as the unit of account instead of balances, in order for it to be compatible with DeFi. 
    - ozToken --> Custom rebasing ERC20, inheriting from several of Open Zeppelin's Upgradeable contracts, such as [EIP712Upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/cryptography/EIP712Upgradeable.sol).
    - wozToken --> [Open Zeppelin's ERC20PermitUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/ERC20Upgradeable.sol).
  - Beacon:
    - Used as the upgradeability core to allow to change the implementations of all oz/wozTokens with one call.
    - Modified version of [Open Zeppelin's Upgradeable Beacon](https://docs.openzeppelin.com/contracts/3.x/api/proxy#UpgradeableBeacon), so it would allow to use two implementations (one for ozTokens and another for woz) instead of one.
- The rebasing mechanism uses a combination of two observations (the previous -from 24 hrs ago- and current one) from Uniswap V3's TWAP oracle on the rETH/ETH 0.05% pool; and fixed-point math operations, on 27-decimals numbers, done with a custom library ([FixedPointMathRayLib](https://github.com/trojanMcAfee/ozel-vn1/blob/main/contracts/libraries/FixedPointMathRayLib.sol)) that leverages User Defined Value Types and [SimonSuckut's Solidity_Uint512 library](https://github.com/SimonSuckut/Solidity_Uint512).
  - This is to avoid precision loss and to keep the ozERC20 pegged to $1 while still accruing rewards. 
- Through the [ozOracle](https://github.com/trojanMcAfee/ozel-vn1/blob/main/contracts/facets/ozOracle.sol) facet, fetching prices for rETHETH and ETHUSD is done with a fail-safe mechanism that includes:
   - A cross-check between Uniswap's TWAP oracles and Chainlink feeds with a median deviation of 100 basis points (1%).
   - If that check fails, it grabs the median of:
     - For ETHUSD --> the Uniswap's V3 WETHUSD 0.05% pool, and [Tellor](https://tellor.io/) & [RedStone](https://redstone.finance/)'s last readings.
     - For rETHETH --> Uniswap's V3 rETHETH 0.01% pool and [RocketPool](https://rocketpool.net/)'s native rETH<>ETH exchange rate.
- The OZL token follows the ERC20 standard, using an exchange rate model to accrue value (instead of rebasing) in the same way that rETH does it.
- The distribution of OZL tokens to the users of the protocol is done in the [OZLrewards](https://github.com/trojanMcAfee/ozel-vn1/blob/main/contracts/facets/OZLrewards.sol) facet, with a modified version of [Synthethix's Staking Rewards contract](https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol) .
- The distribution of OZL tokens to the team and [Protocol Guild](https://protocol-guild.readthedocs.io/en/latest/) is done through [Open Zeppelin's Vesting Wallet](https://docs.openzeppelin.com/contracts/4.x/api/finance#VestingWallet) contract, with a vesting period of 1 year.

## High level overview of the System Architecture
The following diagram only includes the main contracts in order to show the most important relationships between the key sections: 

<img width="1044" alt="image" src="https://github.com/trojanMcAfee/staking-wrapper/assets/59457858/bc2cb788-4e3b-496f-992f-619712d98b14">


## Running the PoC 
For seeing how the system behaves, such as the creation, minting, and redeeming of ozTokens, collecting the Admin Fee and the claiming & redeeming of OZL:
   - Pull the proper Docker image with `docker pull dnyrm/ozel-vn1:0.0.9`.
   - Run the Docker container with `docker run -it dnyrm/ozel-vn1:0.0.9`.
   - The test that's ran is `test_poc()`.

This test comes already with a valid Alchemy endpoint so it can run without issues on a mainnet fork.

## Tests
This projects follows the [Branching Tree Technique](https://x.com/PaulRBerg/status/1682346315806539776) for the unit tests that were performed (for `ozToken.sol`), before the Edge Case was found. These are in the `test/foundry/unit/concrete/OzToken` directory. 

There are also integrations tests that proves the validity of all the claims (economical and technological) that hold true throughout the protocol, such as "the peg of $1 USD of ozTokens will remain despite ETHUSD's volatility". For running these tests:
   - Pull the proper Docker image with `docker pull dnyrm/ozel-vn1:0.0.11`.
   - Run the Docker container with `docker run -it dnyrm/ozel-vn1:0.0.11`.
   - They come already with a valid Alchemy endpoint so it can run without issues on a mainnet fork.
   - This would be the output's last line, with the summary of the full testing campaign:

<img width="725" alt="image" src="https://github.com/trojanMcAfee/ozel-vn1/assets/59457858/88e16075-102c-4575-91df-6e056d6f7113">

The skipped ones are unit tests. 


## Edge Case 
This is the reason why this project's development has been halted. 

Even though I designed an algorithm that preserves the pegged of the ozTokens to $1 despite of ETHUSD's volatility, either up and down, I failed to recognize immediately, until further testing took place, that a decrease in the ETHUSD price would leave the ozTokens unbacked to their fullest since their backing depends directly on the value of rETHUSD, which depends on ETHUSD. 

Staking rewards could have been used to fill in this void (as it was the initial intention of the algorithm ), but it was never going to be enough to keep the protocol out of insolvency, especially with the sudden downturns that the crypto markets have us used to already. 

If you would like to see this Edge Case scenario on a test: 
   - Pull the proper Docker image with `docker pull dnyrm/ozel-vn1:0.0.10`.
   - Run the Docker container with `docker run -it dnyrm/ozel-vn1:0.0.10`.
   - The test that's ran is `test_project_destroyer()`.
   - This test comes already with a valid Alchemy endpoint so it can run without issues on a mainnet fork.
   - This would be the output:
     
     <img width="483" alt="image" src="https://github.com/trojanMcAfee/ozel-vn1/assets/59457858/b80eac52-3a26-4148-a409-36ec5a085f80">
     
     It indicantes a loss of 21.11 DAI over an initial amount of 50 DAI sent to the protocol, after ETHUSD price went from 1677.40 to 970.04.

There are a several possible scenarions where this edge case can be fixed, such as the tokenization of margin positions and using them to hedge the initial purchase of rETH, but the current state of protocols and liquidity working in that market is nowhere near, at this moment, of where it should be to successfully address the needs that this project requires. 
