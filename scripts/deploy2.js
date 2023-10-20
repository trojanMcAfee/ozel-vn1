
const { 
  ozDiamondAddr,
  deployer2,
  registry,
  diamondABI
} = require("../state-vars");

const { 
  impersonateAccount,
  stopImpersonatingAccount
} = require("@nomicfoundation/hardhat-network-helpers");

const {
  sendETHOps
} = require("./helpers");

// async function main() {
//   const currentTimestampInSeconds = Math.round(Date.now() / 1000);
//   const unlockTime = currentTimestampInSeconds + 60;

//   const lockedAmount = hre.ethers.parseEther("0.001");

//   const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
//     value: lockedAmount,
//   });

//   await lock.waitForDeployment();

//   console.log(
//     `Lock with ${ethers.formatEther(
//       lockedAmount
//     )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
//   );
// }


async function main() {

  /**
   * Deploying and integrsting V2 to the DIAMOND
   */
  const Init = await hre.ethers.getContractFactory("DiamondInit");
  const init = await Init.deploy(); 
  await init.deployed();
  console.log('Init deployed to: ', init.address);

  const TokenFactory = await hre.ethers.getContractFactory("ozTokenFactory");
  const tokenFactory = await TokenFactory.deploy();
  await tokenFactory.deployed();
  console.log('ozTokenFactory deployed to: ', tokenFactory.address);

  //FacetCut
  const createTokenSelector = tokenFactory.interface.getSighash("createOzToken");
  const facetCutArgs = [
    [tokenFactory.address, 0, [createTokenSelector]]
  ];
  const facetAddresses = [ tokenFactory.address ];

  //Init
  // const initArgs = [
  //   registry,
    
  // ];
  const initData = init.interface.encodeFunctionData('init', [registry]);

  await sendETHOps(1, deployer2);

  await impersonateAccount(deployer2);
  const deployerSigner = await hre.ethers.provider.getSigner(deployer2);
  
  const ozDiamond = await hre.ethers.getContractAt(diamondABI, ozDiamondAddr);
  let tx = await ozDiamond.connect(deployerSigner).diamondCut(facetCutArgs, init.address, initData);
  let receipt = await tx.wait();
  console.log("Ozel upgraded to V2: ", receipt.transactionHash);
  await stopImpersonatingAccount(deployer2);

  /**
   * END
   */

  const erc20 = await ozDiamond.createOzToken(registry[0], 100);
  console.log('erc20: ', erc20);
  console.log('registtr[0]: ', registry[0]);


}


main();
