class Month {
    constructor(name, days) {
        this.name = name;
        this.days = days;
        this.ETHprice = undefined;
        this.rewardRate = undefined;
        this.rewardsInETH = undefined;
    }

    setValue(varName, value) {
        switch(varName) {
            case 'ETHprice':
                this.ETHprice = value;
                break;
            case 'rewardRate':
                this.rewardRate = value;
            case 'rewardsInETH':
                this.rewardsInETH = value;
                break;
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