const { deployDiamond } = require('./deploy');
const { diamondABI } = require('./state-vars');


async function main() {

    const diamondAddr = await deployDiamond();
    const diamond = await hre.ethers.getContractAt(diamondABI, diamondAddr);

    const facets = await diamond.facetAddresses();
    console.log('facets: ', facets);

}



main();