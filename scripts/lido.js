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

async function queryKraken(targetTimestamp) {
    const krakenURL = `https://api.kraken.com/0/public/OHLC?pair=ETHUSD&interval=1440&since=${targetTimestamp - 10000000}`;

    const result = await axios.get(krakenURL);
    const data = result.data; // Axios automatically parses JSON response
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

    console.log('Closest Value:', closestValue);
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

    for (let i=0; i < 2; i++) {
        let eventRate = Number(totalRewards[i].apr) / 12;
        rewardsRate.push(eventRate);
        console.log('eventRate: ', eventRate);

        let targetTimestamp = totalRewards[i].blockTime;
        console.log('targetTimestamp: ', targetTimestamp);

        let currentEthPrice = await queryKraken(targetTimestamp);
        ETHprices.push(currentEthPrice);
        console.log('ETHUSD: ', currentEthPrice);

        let ethBought = principal / currentEthPrice;
        console.log('ethBought: ', ethBought);

        let ethReward = (eventRate * ethBought) / 100;
        rewardsInETH.push(ethReward);
        totalRewardsInETH += ethReward;
        console.log('ethReward: ', ethReward);

        let usdReward = ethReward * currentEthPrice;
        rewardsInUSD.push(usdReward);
        totalRewardsInUSD += Number(usdReward);
        console.log('usdReward: ', usdReward);
        console.log('');
        console.log('');
    }

    console.log('totalRewardsInETH: ', totalRewardsInETH);
    console.log('totalRewardsInUSD: ', totalRewardsInUSD);
    console.log('l: ', rewardsInUSD.length);
}


main();