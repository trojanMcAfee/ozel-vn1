let usdcAddr;
let usdtAddr;
let wethAddr;
let usdcAddrImpl;
let wethUsdPoolUni; //not used. Remove
let swapRouterUni;
let ethUsdChainlink;
let vaultBalancer;
let queriesBalancer;
let rEthAddr;
let rEthWethPoolBalancer;
let accessControlledOffchainAggregator;
let aeWETH;
let rEthEthChainlink;
let rEthImpl;
let feesCollectorBalancer;
let fraxAddr; //doesn't have a pool in Uniswap Arb, so it can only be used in L1.
let daiAddr;
const defaultSlippage = 50; //5 -> 0.05%; / 100 -> 1% / 50 -> 0.5%

const diamondABI = [
    'function facetAddresses() external view returns (address[] memory facetAddresses_)',
    'function createOzToken(address,string,string,uint8) external returns(address)'
];

const ops = {
    gasLimit: ethers.BigNumber.from('5000000'),
    gasPrice: ethers.BigNumber.from('5134698068')
};
   


let network = 'arbitrum';
switch (network) {
    case 'arbitrum': 
        usdcAddr = '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8';
        usdtAddr = '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9';
        wethAddr = '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1';
        usdcAddrImpl = '0x0f4fb9474303d10905AB86aA8d5A65FE44b6E04A';
        wethUsdPoolUni = '0xC6962004f452bE9203591991D15f6b388e09E8D0'; //not used. Remove
        swapRouterUni = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
        ethUsdChainlink = '0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612';
        vaultBalancer = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
        queriesBalancer = '0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5';
        rEthAddr = '0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8';
        rEthWethPoolBalancer = '0xadE4A71BB62bEc25154CFc7e6ff49A513B491E81';
        accessControlledOffchainAggregator = '0x3607e46698d218B3a5Cae44bF381475C0a5e2ca7';
        aeWETH = '0x8b194bEae1d3e0788A1a35173978001ACDFba668';
        rEthEthChainlink = '0xD6aB2298946840262FcC278fF31516D39fF611eF';
        rEthImpl = '0x3f770Ac673856F105b586bb393d122721265aD46';
        feesCollectorBalancer = '0xce88686553686DA562CE7Cea497CE749DA109f9F';
        fraxAddr = '0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F'; //doesn't have a pool in Uniswap Arb, so it can only be used in L1.
        daiAddr = '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1';
        break;
    case 'ethereum':
        usdcAddr = '1'
}

const registry = [usdtAddr];


module.exports = {
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
    rEthEthChainlink,
    diamondABI,
    ops
};