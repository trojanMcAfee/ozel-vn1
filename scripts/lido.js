const axios = require('axios').default;
const fs = require('fs').promises;
const year = require('./data/vars');


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
    function completeMonth(array, varName, month) {
        let acc = 0;
        let days = month.days;

        for (let j=0; j < days; j++) {
            acc += Number(array[j]);

            if (j == days - 1) {
                let = denominator = varName == 'rewardsInETH' || varName == 'rewardsInUSD' ? 1 : days;
                let avg = acc / denominator;
                month.setValue(varName, avg);
                array.slice(0, days - 1);
            }
        }
    }


    function setRewards(rewardsArray, varName) {
        for (let i=0; i < rewardsArray.length; i++) {
            let currentRewards = rewardsArray[i];

            if (i < 31) year.months[0][varName].push(currentRewards);
            if (i >= 31 && i < 59) year.months[1][varName].push(currentRewards); //feb
            if (i >= 59 && i < 90) year.months[2][varName].push(currentRewards); //mar
            if (i >= 90 && i < 120) year.months[3][varName].push(currentRewards); //apr
            if (i >= 120 && i < 151) year.months[4][varName].push(currentRewards); //may
            if (i >= 151 && i < 181) year.months[5][varName].push(currentRewards); //jun
            if (i >= 181 && i < 212) year.months[6][varName].push(currentRewards); //jul
            if (i >= 212 && i < 243) year.months[7][varName].push(currentRewards); //aug
            if (i >= 243 && i < 273) year.months[8][varName].push(currentRewards); //sep
            if (i >= 273 && i < 304) year.months[9][varName].push(currentRewards); //oct
            if (i >= 304 && i < 334) year.months[10][varName].push(currentRewards); //nov
            if (i >= 334 && i < 365) year.months[11][varName].push(currentRewards); //dec
        }


        for (let j=0; j < year.months.length; j++) {
            let month = year.months[j];

            let acc = 0;
            for (let i=0; i < month[varName].length; i++) {
                let reward = month[varName][i];
                acc += reward;
            }

            month.setValue(varName, acc);
            // console.log('total: ', acc);

        }
    }

    //----------

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

        // for (let key in results) {
        //     let values = results[key];

        //     for (let i=0; i < year.months.length; i++) {
        //         let month = year.months[i];

        //         completeMonth(values, key, month);
        //     }
        // }


        console.log('year: ', year.months);

        const march = year.months[2];
        console.log('');
        console.log('---- March ----');
        console.log('l: ', march.rewardsInUSD.length);

        let acc = 0;
        for (let i=0; i < march.rewardsInUSD.length; i++) {
            let reward = march.rewardsInUSD[i];
            acc += reward;
        }
        console.log('total: ', acc);

        // let totalRewardsInUSD = 0;
        // let totalRewardsInETH = 0;
        // for (let i=0; i < year.months.length; i++) {
        //     totalRewardsInUSD += year.months[i].totalRewardsInUSD;
        //     totalRewardsInETH += year.months[i].totalRewardsInETH;
        // }
        // console.log('');
        // console.log('totalRewardsInUSD: ', totalRewardsInUSD);
        // console.log('totalRewardsInETH: ', totalRewardsInETH);

    } catch (error) {
        console.error('Error reading results file:', error);
    }
}


async function main3() {
    const jan = [
        117.94062861059268,
        121.5542990960402,
        126.65405688737901,
        133.47592243328018,
        151.65972681582664,
        123.55773388525758,
        124.4092777367219,
        117.62779366275134,
        145.17401209119575,
        129.7736872064771,
        122.5741539209645,
        146.1562418937195,
        151.79137408281505,
        165.5869145548191,
        132.28113539478005,
        139.11859401344964,
        138.26920589062948,
        133.25118140079485,
        151.5380141036535,
        123.51148221672442,
        145.96691306186688,
        126.748235243127,
        127.48710360929537,
        139.92312751200168,
        149.4097504647803,
        139.669070955869,
        156.9288873941427,
        127.47816343701626,
        123.01852060552035,
        128.01335545210696,
        132.62383464289783
    ];

    const feb = [
        129.99338169046447,
        141.33359314147833,
        136.00039116475182,
        137.52970990581605,
        127.04489571611029,
        125.86254908895377,
        136.89826035635932,
        140.91905035051803,
        148.11811879055202,
        141.60577537167492,
        131.3665878781617,
        121.83117012338036,
        137.1470642789202,
        130.82340415781061,
        178.66810440488277,
        146.02325015304484,
        138.54349001217366,
        150.24175267809215,
        137.79138866892598,
        134.18761481134587,
        139.07831183195694,
        146.87402649231632,
        138.55994743287727,
        129.94084561011672,
        124.47848149677844,
        115.21599183167626,
        111.38561494136815,
        125.91605604382242,
    ];

    let acc = 0;
    for (let i=0; i < feb.length; i++) {
        acc += feb[i];
    }

    console.log('total: ', acc);
    console.log('length: ', feb.length);


}


async function main() {
    // await dailyCalculation();
    await monthlyCalculation();
}


main();