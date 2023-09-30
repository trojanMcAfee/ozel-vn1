const { ethers } = require('ethers');
const { parseEther } = hre.ethers;

async function sendETHOps(amount, receiver) {
    const [signer] = await hre.ethers.getSigners();
    // let balance = await signer.getBalance();
    
    tx = await signer.sendTransaction({
        value: parseEther(amount.toString()),
        to: receiver,
        gasLimit: ethers.BigNumber.from('5000000'),
        gasPrice: ethers.BigNumber.from('5134698068')
    });
    await tx.wait();

    // balance = await signer.getBalance();
}

module.exports = {
    sendETHOps
};