const axios = require('axios').default;
const fs = require('fs').promises;
const { year, principal, setRewards, setAvg, setAPR } = require('./data/vars');


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

    //vwap price
    return closestValue[5];
}


async function dailyCalculation() { 
    const result = await axios.post(URL, query());
    const { totalRewards } = result.data.data;
    const principal = 1_000_000;
    const ETHprices = [];
    const rewardsRate = [];
    const rewardsInETH = [];
    const rewardsInUSD = [];
    let totalRewardsInETH = 0;
    let totalRewardsInUSD = 0;
    let initialETHbuy = 0;

    for (let i=0; i < totalRewards.length; i++) {
        console.log(i);

        try {
            //Event rate is daily
            let eventRate = Number(totalRewards[i].apr) / 365;
            rewardsRate.push(eventRate);

            let targetTimestamp = totalRewards[i].blockTime;

            if (i % 8 == 0) await delay(10000);

            let currentEthPrice = await queryKraken(targetTimestamp);
            ETHprices.push(currentEthPrice);

            let ethBought = principal / currentEthPrice;
            if (i == 0) initialETHbuy = ethBought;

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
    console.log('initialETHbuy: ', initialETHbuy);

    const apr_USD = (totalRewardsInUSD * 100) / principal;
    const apr_ETH = (totalRewardsInETH * 100) / initialETHbuy;
    console.log('APR in USD / event-base settlement rate: ', apr_USD);
    console.log('APR in ETH / event-base settlement rate: ', apr_ETH);

    // totalRewardsInETH:  24.702274269024475
    // totalRewardsInUSD:  43525.913768707724
    // rewardsInUSD length:  365
    // rewardsInETH length:  365
    // rewardsRate length:  365
    // ETHprices length:  365
    // APR in USD / event-base settlement rate:  4.352591376870773
    // APR in ETH / event-base settlement rate:  3.0019191782689303

    const results = {
        ETHprices,
        rewardsRate,
        rewardsInETH,
        rewardsInUSD,
        totalRewards: {
            totalRewardsInETH,
            totalRewardsInUSD,
            apr_ETH,
            apr_USD
        },
        initialETHbuy
    };

    await fs.writeFile('results.json', JSON.stringify(results, null, 2));
    console.log('Results saved to results.json');
}

//------------------

async function monthlyCalculation() {
    try {
        const data = await fs.readFile('scripts/data/data.json', 'utf8');
        const results = JSON.parse(data);

        delete results.totalRewards;
        delete results.initialETHbuy;

        const { 
            ETHprices,
            rewardsRate,
            rewardsInETH,
            rewardsInUSD
        } = results;

        setRewards(rewardsInUSD, 'rewardsInUSD');
        setRewards(rewardsInETH, 'rewardsInETH');
        setRewards(ETHprices, 'ETHprices');

        setAvg(ETHprices, 'ETHprice');
        setAvg(rewardsRate, 'rewardsRate');

        setAPR('inETH');
        setAPR('inUSD');

        let totalRewardsInUSD = 0;
        let totalRewardsInETH = 0;
        for (let i=0; i < year.months.length; i++) {
            totalRewardsInUSD += year.months[i].totalRewards.inUSD.total;
            totalRewardsInETH += year.months[i].totalRewards.inETH.total;
        }
        console.log('');
        console.log('totalRewardsInUSD: ', totalRewardsInUSD);
        console.log('totalRewardsInETH: ', totalRewardsInETH);

    } catch (error) {
        console.error('Error reading results file:', error);
    }
}


async function setYear() {
    const inAsset = ['inUSD', 'inETH'];

    for (let i=0; i < inAsset.length; i++) {
        let acc = 0;
        for (let j=0; j < year.months.length; j++) {
            let month = year.months[j];
            acc += month.totalRewards[inAsset[i]].apr;
        }
        year.apr.monthlyAvg[inAsset[i]] = acc;
    }

    for (let i=0; i < inAsset.length; i++) {
        let acc = 0;
        for (let j=0; j < year.months.length; j++) {
            let month = year.months[j];
            let rewardType = inAsset[i] == 'inUSD' ? 'rewardsInUSD' : 'rewardsInETH';

            for (let z=0; z < month[rewardType].length; z++) {
                if (rewardType == 'rewardsInETH') {
                    let currPrice = month.ETHprices[z];
                    let buyIn = principal / currPrice;
                    let currDailyRate = (month[rewardType][z] * 100) / buyIn;
                    acc += currDailyRate;
                } else {
                    acc += month[rewardType][z];
                }
            }
        }

        if (inAsset[i] == 'inUSD') {
            year.apr.dailyAvg.inUSD = (acc * 100) / principal;
        } else {
            year.apr.dailyAvg.inETH = acc;
        }
    }
}


async function main() {
    // await dailyCalculation();
    await monthlyCalculation();
    //------
    await setYear();
    console.log('year2: ', year.apr);
    // console.log('year: ', year.months[0].totalRewards);

    // await fs.writeFile('scripts/data/filtered.json', JSON.stringify(year, null, 2));
}


main();

