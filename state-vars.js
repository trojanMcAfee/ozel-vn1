const ozDiamondAddr = '0x7D1f13Dd05E6b0673DC3D0BFa14d40A74Cfa3EF2';
const deployer2 = '0xe738696676571D9b74C81716E4aE797c2440d306';

const opsL2_2 = {
    gasLimit: ethers.BigNumber.from('5000000'),
    gasPrice: ethers.BigNumber.from('5134698068')
};
    
const diamondABI = [
    'function setTESTVAR2(uint256 num_, bytes32 position_) public',
    'function diamondCut((address facetAddress, uint8 action, bytes4[] functionSelectors)[] _diamondCut, address _init, bytes _calldata) external',
    'function getOzelIndex() external view returns (uint256)',
    'function getRegulatorCounter() external view returns (uint256)',
    'function balanceOf(address account) view returns (uint256)',
    'function transfer(address recipient, uint256 amount) returns (bool)',
    'function exchangeToAccountToken(bytes,uint256,address) external payable',
    'function withdrawUserShare(bytes,address,uint256) external',
    'function enableWithdrawals(bool state_) external',
    'function updateExecutorState(uint256 amount_, address user_, uint256 lockNum_) external payable',
    'function deposit(uint256 assets, address receiver, uint256 lockNum_) external payable returns (uint256 shares)',
    'function executeFinalTrade(tuple(int128 tokenIn, int128 tokenOut, address baseToken, address token, address pool) swapDetails_, uint256 slippage, address user_, uint256 lockNum_) external payable',
    'function redeem(uint256 shares, address receiver, address owner, uint256 lockNum_) external returns (uint256 assets)',
    'function burn(address account, uint256 amount, uint256 lockNum_) external',
    'function modifyPaymentsAndVolumeExternally(address user_, uint256 newAmount_, uint256 lockNum_) external',
    'function addTokenToDatabase((int128 tokenIn, int128 tokenOut, address baseToken, address token, address pool) newSwap_, (address l1Address, address l2Address) token_) external',
    'function transferUserAllocation(address sender_, address receiver_, uint256 amount_, uint256 senderBalance_, uint256 lockNum_) external',
    'function owner() external view returns (address owner_)',
    'function queryTokenDatabase(address token_) external view returns (bool)',
    'function getAUM() external view returns (uint,uint)',
    'function getTotalVolumeInETH() external view returns(uint)',
    'function getTotalVolumeInUSD() external view returns(uint)',
    'function getOzelBalances(address) external view returns (uint,uint)',
    'function removeTokenFromDatabase((int128,int128,address,address,address) swapToRemove_, (address l1Address, address l2Address) token_) external',
    'function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_)',
    'function getProtocolFee() external view returns(uint)',
    'function changeL1Check(bool newState_) external',
    'function getAccountPayments(address) external view returns(uint256)',
    'function getUserByL1Account(address) external view returns(address)',
    'function setAuthorizedCaller(address caller_, bool newStatus_) external',
    'function getFunds() external',
    'function createNewProxy((address,address,uint16,string)) external',
    'function getAccountsByUser(address) external view returns(address[],string[])',
    'function authorizeSelector(bytes4, bool) external',
    'function facetAddresses() external view returns (address[])',
    'function getTaskID(address,address) external view returns(bytes32)',
    'function getTokenDatabase() external view returns(address[] memory)',
    'function getLastPrice() external view returns(uint256)',
    'function facetFunctionSelectors(address _facet) external view returns (bytes4[] facetFunctionSelectors_)',
    'function getEnergyPrice() external view returns(uint256)'
];

let network = 'arbitrum';

switch(network) {
case 'arbitrum':
    
    break;
case 'mainnet':
}



module.exports = {
    diamondABI,
    ozDiamondAddr,
    deployer2,
    opsL2_2,
};