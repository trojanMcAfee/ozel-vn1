const { ethers } = require('ethers');
const { parseEther } = ethers.utils;

async function sendETHOps(amount, receiver) {
    const [signer] = await hre.ethers.getSigners();
    
    tx = await signer.sendTransaction({
        value: parseEther(amount.toString()),
        to: receiver,
        gasLimit: ethers.BigNumber.from('5000000'),
        gasPrice: ethers.BigNumber.from('5134698068')
    });
    await tx.wait();

}

module.exports = {
    sendETHOps
};