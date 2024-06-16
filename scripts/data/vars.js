class Month {
    constructor(name, days) {
        this.name = name;
        this.days = days;
        this.ETHprice = undefined;
        this.rewardsRate = undefined;
        this.totalRewardsInETH = undefined;
        this.totalRewardsInUSD = undefined;
    }

    setValue(varName, value) {
        switch(varName) {
            case 'ETHprices':
                this.ETHprice = value;
                break;
            case 'rewardsRate':
                this.rewardsRate = value;
            case 'rewardsInETH':
                this.totalRewardsInETH = value;
                break;
            case 'rewardsInUSD':
                this.totalRewardsInUSD = value;
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

const year = {
    months: [jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec],
    thirtyOne: 7,
    twentyEight: 1,
    thirty: 4
};

module.exports = year;