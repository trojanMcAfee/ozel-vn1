const { deployDiamond } = require('./deploy');
const { 
    diamondABI,
    usdcAddr,
    ops
} = require('./state-vars');

const { hexStripZeros } = ethers.utils;


async function main() {
    const diamondAddr = await deployDiamond();
    const diamond = await hre.ethers.getContractAt(diamondABI, diamondAddr);

    const USDC = await hre.ethers.getContractAt('IERC20Permit', usdcAddr);

    //-------------------

    let tx = await diamond.createOzToken(
        usdcAddr, "Ozel-ERC20", "ozERC20", await USDC.decimals(), ops
    );
    let receipt = await tx.wait();

    const ozTokenAddr = hexStripZeros(receipt.events[2].topics[1])

    

}



main();