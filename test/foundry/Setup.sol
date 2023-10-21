// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import "../../contracts/interfaces/ozIDiamond.sol";
import "../../contracts/upgradeInitializers/DiamondInit.sol";
import {Test} from "forge-std/Test.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
import "../../contracts/interfaces/IERC20Permit.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ROImoduleL2} from "../../contracts/facets/ROImoduleL2.sol";
import "../../contracts/facets/DiamondCutFacet.sol";
import "../../contracts/facets/DiamondLoupeFacet.sol";
import "../../contracts/facets/OwnershipFacet.sol";
import "../../contracts/facets/MirrorExchange.sol";
import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";
import "../../contracts/facets/Pools.sol";
import "../../contracts/Diamond.sol";
import {IDiamondCut} from "../../contracts/interfaces/IDiamondCut.sol";
import {ozOracles} from "../../contracts/facets/ozOracles.sol"; 
import {ozBeacon} from "../../contracts/facets/ozBeacon.sol";
import {ozLoupe} from "../../contracts/facets/ozLoupe.sol";
import {ozToken} from "../../contracts/ozToken.sol";

// import "forge-std/console.sol";


contract Setup is Test {

    uint OWNER_PK = 123;
    uint ALICE_PK = 456;
    uint BOB_PK = 789;

    address internal owner;
    address internal alice;
    address internal bob;
   
    enum Network {
        ARBITRUM,
        ETHEREUM
    }


    //ERC20s
    address internal usdtAddr;
    address internal usdcAddr;
    address internal wethAddr;
    address internal rEthAddr;
    address internal fraxAddr;
    address internal daiAddr;

    //For debugging purposes
    address private usdcAddrImpl;
    address private wethUsdPoolUni;
    address private accessControlledOffchainAggregator; //0x3607e46698d218B3a5Cae44bF381475C0a5e2ca7
    address private aeWETH;
    address private rEthImpl;
    address private feesCollectorBalancer;

    //Contracts
    address internal swapRouterUni;
    address internal ethUsdChainlink;
    address internal vaultBalancer; 
    address internal queriesBalancer;
    address internal rEthWethPoolBalancer;
    address internal rEthEthChainlink;

    address internal testToken;


    //Default diamond contracts and facets
    DiamondInit internal initDiamond;
    DiamondCutFacet internal cutFacet;
    OwnershipFacet internal ownership;
    Diamond internal ozDiamond;
    ozBeacon internal beacon;
    ozToken internal tokenOz;

    //Ozel custom facets
    ozTokenFactory internal factory; 
    MirrorExchange internal mirrorEx;  
    Pools internal pools;
    ROImoduleL2 internal roiL2;
    ozOracles internal oracles;
    ozLoupe internal loupe;

    ozIDiamond internal OZ;

    uint defaultSlippage = 50; //5 -> 0.05%; / 100 -> 1% / 50 -> 0.5%

    uint internal constant _BASE = 18;

    /** FUNCTIONS **/
    
    function setUp() public {
        (string memory network, uint blockNumber) = _chooseNetwork(Network.ARBITRUM);
        vm.createSelectFork(vm.rpcUrl(network), blockNumber);
        _runSetup();
    }

    function _chooseNetwork(Network chain_) private returns(string memory network, uint blockNumber) {
        if (chain_ == Network.ARBITRUM) {
            usdtAddr = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
            usdcAddr = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
            wethAddr = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
            usdcAddrImpl = 0x0f4fb9474303d10905AB86aA8d5A65FE44b6E04A;
            wethUsdPoolUni = 0xC6962004f452bE9203591991D15f6b388e09E8D0; //not used. Remove
            swapRouterUni = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            ethUsdChainlink = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
            vaultBalancer = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
            queriesBalancer = 0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5;
            rEthAddr = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;
            rEthWethPoolBalancer = 0xadE4A71BB62bEc25154CFc7e6ff49A513B491E81;
            accessControlledOffchainAggregator = 0x3607e46698d218B3a5Cae44bF381475C0a5e2ca7;
            aeWETH = 0x8b194bEae1d3e0788A1a35173978001ACDFba668;
            rEthEthChainlink = 0xD6aB2298946840262FcC278fF31516D39fF611eF;
            rEthImpl = 0x3f770Ac673856F105b586bb393d122721265aD46;
            feesCollectorBalancer = 0xce88686553686DA562CE7Cea497CE749DA109f9F;
            fraxAddr = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F; //doesn't have a pool in Uniswap Arb, so it can only be used in L1.
            daiAddr = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

            network = "arbitrum";
            blockNumber = 136177703;
        } else if (chain_ == Network.ETHEREUM) {
            usdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
            usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            usdcAddrImpl = 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF;
            wethUsdPoolUni = 0xC6962004f452bE9203591991D15f6b388e09E8D0; //put the same as arb for the moment. Fix this
            swapRouterUni = 0xE592427A0AEce92De3Edee1F18E0157C05861564; //same as arb
            ethUsdChainlink = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
            vaultBalancer = 0xBA12222222228d8Ba445958a75a0704d566BF2C8; //same as arb
            queriesBalancer = 0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5; //same as arb
            rEthAddr = 0xae78736Cd615f374D3085123A210448E74Fc6393;
            rEthWethPoolBalancer = 0x1E19CF2D73a72Ef1332C882F20534B6519Be0276;
            accessControlledOffchainAggregator = address(0);
            aeWETH = address(0);
            rEthEthChainlink = 0x536218f9E9Eb48863970252233c8F271f554C2d0;
            rEthImpl = address(0);
            feesCollectorBalancer = address(0);
            fraxAddr = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
            daiAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

            network = "ethereum";
            blockNumber = 18284413;
        }
    }


    function _runSetup() internal {
        //*** SETS UP THE ERC20 TOKEN TO TEST WITH ****/
        testToken = usdcAddr;

        //Initial users config
        owner = vm.addr(OWNER_PK);
        alice = vm.addr(ALICE_PK);
        bob = vm.addr(BOB_PK);
        deal(testToken, alice, 1500 * (10 ** IERC20Permit(testToken).decimals()));
        deal(testToken, bob, 2000 * (10 ** IERC20Permit(testToken).decimals()));

        //Deploys diamond infra
        cutFacet = new DiamondCutFacet();
        ozDiamond = new Diamond(owner, address(cutFacet));
        initDiamond = new DiamondInit();

        //Deploys ozToken implementation contract for ozBeacon
        tokenOz = new ozToken();

        //Deploys facets
        // loupe = new DiamondLoupeFacet();
        loupe = new ozLoupe();
        ownership = new OwnershipFacet();
        mirrorEx = new MirrorExchange();
        factory = new ozTokenFactory();
        pools = new Pools();
        roiL2 = new ROImoduleL2();
        oracles = new ozOracles();
        beacon = new ozBeacon(address(tokenOz));

        //Create initial FacetCuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](8);
        cuts[0] = _createCut(address(loupe), 0);
        cuts[1] = _createCut(address(ownership), 1);
        cuts[2] = _createCut(address(mirrorEx), 2);
        cuts[3] = _createCut(address(factory), 3);
        cuts[4] = _createCut(address(pools), 4);
        cuts[5] = _createCut(address(roiL2), 5);
        cuts[6] = _createCut(address(oracles), 6);
        cuts[7] = _createCut(address(beacon), 7);

        //Create ERC20 registry
        address[] memory registry = new address[](1);
        registry[0] = usdtAddr;

        bytes memory initData = abi.encodeWithSelector(
            initDiamond.init.selector, 
            registry,
            address(ozDiamond),
            swapRouterUni,
            ethUsdChainlink,
            wethAddr,
            defaultSlippage,
            vaultBalancer,
            queriesBalancer,
            rEthAddr,
            rEthWethPoolBalancer,
            rEthEthChainlink,
            address(beacon)
        );

        OZ = ozIDiamond(address(ozDiamond));

        //Initialize diamond
        vm.prank(owner);
        OZ.diamondCut(cuts, address(initDiamond), initData);

        //Sets labels
        _setLabels(); 
    }


    function _createCut(
        address contractAddr_, 
        uint id_
    ) private view returns(IDiamondCut.FacetCut memory cut) {
        uint length;
        if (id_ == 0) {
            length = 6;
        } else if (id_ == 1) {
            length = 2;
        } else if (id_ == 2 || id_ == 4 || id_ == 5 || id_ == 6) {
            length = 1;
        } else if (id_ == 3) {
            length = 3;
        } else if (id_ == 7) {
            length = 5;
        }

        bytes4[] memory selectors = new bytes4[](length);

        if (id_ == 0) {
            selectors[0] = loupe.facets.selector;
            selectors[1] = loupe.facetFunctionSelectors.selector;
            selectors[2] = loupe.facetAddresses.selector;
            selectors[3] = loupe.facetAddress.selector;
            selectors[4] = loupe.supportsInterface.selector;
            selectors[5] = loupe.getRewardMultiplier.selector;
        } else if (id_ == 1) {
            selectors[0] = ownership.transferOwnershipDiamond.selector;
            selectors[1] = ownership.ownerDiamond.selector;
        } else if (id_ == 2) { //MirrorEx
            selectors[0] = 0xe9e05c42;
        } else if (id_ == 3) {
            selectors[0] = factory.createOzToken.selector;
            selectors[1] = factory.getOzTokenRegistry.selector;
            selectors[2] = factory.isInRegistry.selector;
        } else if (id_ == 4) { //Pools
            selectors[0] = 0xe9e05c43;
        } else if (id_ == 5) {
            selectors[0] = roiL2.useUnderlying.selector;
        } else if (id_ == 6) {
            selectors[0] = oracles.rETH_ETH.selector;
        } else if (id_ == 7) {
            selectors[0] = beacon.implementation.selector;
            selectors[1] = beacon.upgradeTo.selector;
            selectors[2] = beacon.owner.selector;
            selectors[3] = beacon.renounceOwnership.selector;
            selectors[4] = beacon.transferOwnership.selector;
        }

        cut = IDiamondCut.FacetCut({
            facetAddress: contractAddr_,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
    }

    function _setLabels() private {
        vm.label(address(factory), "ozTokenFactory");
        vm.label(address(initDiamond), "DiamondInit");
        vm.label(address(roiL2), "ROImoduleL2");
        vm.label(owner, "owner");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(usdcAddr, "USDCproxy");
        vm.label(usdtAddr, "USDT");
        vm.label(address(ozDiamond), "ozDiamond");
        vm.label(address(initDiamond), "DiamondInit");
        vm.label(address(cutFacet), "DiamondCutFacet");
        vm.label(address(loupe), "ozLoupe");
        vm.label(address(ownership), "OwnershipFacet");
        vm.label(address(mirrorEx), "MirrorExchange");
        vm.label(address(pools), "Pools");
        vm.label(swapRouterUni, "SwapRouterUniswap");
        vm.label(ethUsdChainlink, "ETHUSDfeedChainlink");
        vm.label(wethAddr, "WETH");
        vm.label(usdcAddrImpl, "USDCimpl");
        vm.label(wethUsdPoolUni, "wethUsdPoolUni");
        vm.label(rEthWethPoolBalancer, "rETHWETHpoolBalancer");
        vm.label(vaultBalancer, "VaultBalancer");
        vm.label(queriesBalancer, "BalancerQueries");
        vm.label(accessControlledOffchainAggregator, "AccessControlledOffchainAggregator");
        vm.label(aeWETH, "aeWETH");
        vm.label(rEthAddr, "rETH");
        vm.label(rEthImpl, "rETHimpl");
        vm.label(feesCollectorBalancer, "FeesCollectorBalancer");
        vm.label(address(oracles), "ozOracles");
        vm.label(address(beacon), "ozBeacon");
        vm.label(address(tokenOz), "ozTokenImplementation");
        vm.label(fraxAddr, "FRAX");
    }


}