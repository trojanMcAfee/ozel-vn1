class Month {
    constructor(name, days) {
        this.name = name;
        this.days = days;
        this.ETHprice = 0;
        this.rewardsRate = 0;
        this.totalRewards = {
            inETH: {
                total: 0,
                apr: 0
            },
            inUSD: {
                total: 0,
                apr: 0
            }
        };
        this.rewardsInETH = [];
        this.rewardsInUSD = [];
        this.ETHprices = [];
    }

    setValue(varName, value) {
        switch(varName) {
            case 'rewardsInETH':
                this.totalRewards.inETH.total = value;
                break;
            case 'rewardsInUSD':
                this.totalRewards.inUSD.total = value;
        }
    }
}

const jan = new Month('january', 31);
const feb = new Month('february', 28);
const mar = new Month('march', 31);
const apr = new Month('april', 30);
const may = new Month('may', 31);
const jun = new Month('june', 30);
const jul = new Month('july', 31);
const aug = new Month('august', 31);
const sep = new Month('september', 30);
const oct = new Month('october', 31);
const nov = new Month('november', 30);
const dec = new Month('december', 31);

const principal = 1_000_000;

const year = {
    months: [jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec],
    apr: {
        monthlyAvg: {
            inETH: 0,
            inUSD: 0
        },
        dailyAvg: {
            inETH: 0,
            inUSD: 0
        }
    },
    thirtyOne: 7,
    twentyEight: 1,
    thirty: 4
};

function setAvg(array, varName) {
    for (let i=0; i < array.length; i++) {
        let currEthPrice = array[i];

        if (i < 31) year.months[0][varName] += Number(currEthPrice);
        if (i >= 31 && i < 59) year.months[1][varName] += Number(currEthPrice);
        if (i >= 59 && i < 90) year.months[2][varName] += Number(currEthPrice);
        if (i >= 90 && i < 120) year.months[3][varName] += Number(currEthPrice);
        if (i >= 120 && i < 151) year.months[4][varName] += Number(currEthPrice);
        if (i >= 151 && i < 181) year.months[5][varName] += Number(currEthPrice);
        if (i >= 181 && i < 212) year.months[6][varName] += Number(currEthPrice);
        if (i >= 212 && i < 243) year.months[7][varName] += Number(currEthPrice);
        if (i >= 243 && i < 273) year.months[8][varName] += Number(currEthPrice);
        if (i >= 273 && i < 304) year.months[9][varName] += Number(currEthPrice);
        if (i >= 304 && i < 334) year.months[10][varName] += Number(currEthPrice);
        if (i >= 334 && i < 365) year.months[11][varName] += Number(currEthPrice);
    }

    for (let i=0; i < year.months.length; i++) {
        let month = year.months[i];
        month[varName] /= month.days;
    }
}

function setAPR(varName) {
    const principal = 1_000_000;

    for (let i=0; i < year.months.length; i++) {
        let month = year.months[i];
        let ethPrice = month.ETHprice;

        let denominator = principal / ethPrice;

        if (varName == 'inUSD') {
            month.totalRewards[varName].total = month.totalRewards.inETH.total * ethPrice;
            denominator = principal;
        }

        month.totalRewards[varName].apr = (month.totalRewards[varName].total * 100) / denominator;

    }
}


function setRewards(rewardsArray, varName) {
    //rewardsInUSD/ETH
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

    if (varName != 'ETHprices') {
        //totalRewards
        for (let j=0; j < year.months.length; j++) {
            let month = year.months[j];

            let acc = 0;
            for (let i=0; i < month[varName].length; i++) {
                let reward = month[varName][i];
                acc += reward;
            }

            month.setValue(varName, acc);
        }
    }
}

module.exports = {
    year,
    principal,
    setRewards,
    setAvg,
    setAPR
};