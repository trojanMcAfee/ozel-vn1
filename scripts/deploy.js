/* global ethers */
/* eslint prefer-const: "off" */

const {
  registry,
  usdcAddr,
  swapRouterUni,
  ethUsdChainlink,
  wethAddr,
  defaultSlippage,
  vaultBalancer,
  queriesBalancer,
  rEthAddr,
  rEthWethPoolBalancer,
  rEthEthChainlink
} = require("./state-vars");

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js');

const { deployContract } = require('./helpers');

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  // const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  // const diamondCutFacet = await DiamondCutFacet.deploy()
  // await diamondCutFacet.deployed()
  // console.log('DiamondCutFacet deployed:', diamondCutFacet.address)
  const diamondCutFacet = await deployContract('DiamondCutFacet');

  // deploy ozToken as implementation + the Beacon
  // const OzToken = await ethers.getContractFactory('ozToken')
  // const ozToken = await OzToken.deploy()
  // await ozToken.deployed()
  // console.log('ozToken deployed:', ozToken.address)
  const ozToken = await deployContract('ozToken');

  // const Beacon = await ethers.getContractFactory('ozBeacon')
  // const beacon = await Beacon.deploy(ozToken.address)
  // await beacon.deployed()
  // console.log('ozBeacon deployed:', beacon.address)
  const beacon = await deployContract('ozBeacon', ozToken.address);

  // deploy Diamond
  // const Diamond = await ethers.getContractFactory('Diamond')
  // const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
  // await diamond.deployed()
  // console.log('Diamond deployed:', diamond.address)
  const diamond = await deployContract('Diamond', contractOwner.address, diamondCutFacet.address);

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  // const DiamondInit = await ethers.getContractFactory('DiamondInit')
  // const diamondInit = await DiamondInit.deploy()
  // await diamondInit.deployed()
  // console.log('DiamondInit deployed:', diamondInit.address)
  const diamondInit = await deployContract('DiamondInit');

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'OwnershipFacet',
    'MirrorExchange',
    'ozLoupe',
    'ozOracles',
    'ozTokenFactory',
    'Pools',
    'ROImoduleL2'
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  cut.push({
    facetAddress: beacon.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(beacon)
  });

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt

  // call to init function
  const initArgs = [ //check that perhaps ozBeacon and CutFacet are not added to the diamond
    registry,
    diamond.address,
    swapRouterUni,
    ethUsdChainlink,
    wethAddr,
    defaultSlippage,
    vaultBalancer,
    queriesBalancer,
    rEthAddr,
    rEthWethPoolBalancer,
    rEthEthChainlink,
    beacon.address
  ];

  let functionCall = diamondInit.interface.encodeFunctionData('init', initArgs)
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  return diamond.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
