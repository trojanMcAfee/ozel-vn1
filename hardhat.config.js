// require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require('dotenv').config();


module.exports = {
  solidity: {
    version: "0.8.21",
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.ARBITRUM,
        blockNumber: 136177703
      }
    }
  }
};
