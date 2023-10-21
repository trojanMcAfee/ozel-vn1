// const { ethers } = require('ethers');
// const { parseEther } = ethers.utils;

async function sendETHOps(amount, receiver) {
    const [signer] = await hre.ethers.getSigners();
    
    tx = await signer.sendTransaction({
        value: ethers.utils.parseEther(amount.toString()),
        to: receiver,
        gasLimit: ethers.BigNumber.from('5000000'),
        gasPrice: ethers.BigNumber.from('5134698068')
    });
    await tx.wait();
}

async function deployContract(contractName, arg = false, arg2) {
    const Contract = await ethers.getContractFactory(contractName);
    let contract;

    if (contractName == 'Diamond') {
        contract = await Contract.deploy(arg, arg2);
    } else {
        contract = !arg ? await Contract.deploy() : await Contract.deploy(arg)
    }

    await contract.deployed();
    console.log(`${contractName} deployed:`, contract.address)

    return contract;
}

module.exports = {
    sendETHOps,
    deployContract
};