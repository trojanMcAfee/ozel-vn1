const axios = require('axios').default;


const URL = `https://gateway-arbitrum.network.thegraph.com/api/a2bf64d6b822525b225e908912310821/subgraphs/
id/Sxx812XgeKyzQPaBpR5YZWmGV5fZuBaPdh7DFhzSwiQ`;

const query = () => {
    return {
        query: `
        {
            totalRewards(
              first: 1000, 
              where: { 
                blockTime_gte: 1672531200, 
                blockTime_lt: 1704067200 
              }, 
              orderBy: blockTime, 
              orderDirection: asc
            ) {
              id
              totalRewards
              totalRewardsWithFees
              totalFee
              totalPooledEtherBefore
              totalPooledEtherAfter
              totalSharesBefore
              totalSharesAfter
              apr
              aprBeforeFees
              timeElapsed
              block
              blockTime
            }
          }
        `
    }
};

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));


async function queryKraken(targetTimestamp) {
    const krakenURL = `https://api.kraken.com/0/public/OHLC?pair=ETHUSD&interval=1440&since=${targetTimestamp - 10000000}`;

    const result = await axios.get(krakenURL);
    const data = result.data; // Axios automatically parses JSON response
    // console.log('is - false: ', data.error[0]);
    if (data.error[0] !== undefined) console.log(data.error[0]);
    const prices = data.result.XETHZUSD;
    
    // Find the value closest to the given UNIX timestamp
    let closestValue = null;
    let closestDiff = Infinity;

    for (const price of prices) {
        const timestamp = price[0]; // The timestamp is the first value in the OHLC array
        const diff = Math.abs(timestamp - targetTimestamp);
        if (diff < closestDiff) {
            closestDiff = diff;
            closestValue = price;
        }
    }

    // console.log('Closest Value:', closestValue);
    return closestValue[5];
}


async function main() { 
    const result = await axios.post(URL, query());
    const { totalRewards } = result.data.data;
    const principal = 1_000_000;
    const ETHprices = [];
    const rewardsRate = [];
    const rewardsInETH = [];
    const rewardsInUSD = [];
    let totalRewardsInETH = 0;
    let totalRewardsInUSD = 0;

    for (let i=0; i < totalRewards.length; i++) {
        console.log(i);

        try {
            let eventRate = Number(totalRewards[i].apr) / 12;
            rewardsRate.push(eventRate);

            let targetTimestamp = totalRewards[i].blockTime;

            if (i % 8 == 0) await delay(10000);

            let currentEthPrice = await queryKraken(targetTimestamp);
            ETHprices.push(currentEthPrice);

            let ethBought = principal / currentEthPrice;

            let ethReward = (eventRate * ethBought) / 100;
            rewardsInETH.push(ethReward);
            totalRewardsInETH += ethReward;

            let usdReward = ethReward * currentEthPrice;
            rewardsInUSD.push(usdReward);
            totalRewardsInUSD += Number(usdReward);
        } catch(e) {
            console.log('e: ', e);
        }

    }

    console.log('totalRewardsInETH: ', totalRewardsInETH);
    console.log('totalRewardsInUSD: ', totalRewardsInUSD);
    console.log('rewardsInUSD length: ', rewardsInUSD.length);
    console.log('rewardsInETH length: ', rewardsInETH.length);
    console.log('rewardsRate length: ', rewardsRate.length);
    console.log('ETHprices length: ', ETHprices.length);

    const APR = (rewardsInUSD * 100) / principal;
    console.log('APR / event-base settlement rate: ', APR);

    // totalRewardsInETH:  751.360842349494
    // totalRewardsInUSD:  1323913.2104648598
}


main();