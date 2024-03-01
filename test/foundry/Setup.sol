// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozIDiamond} from "../../contracts/interfaces/ozIDiamond.sol";
import "../../contracts/upgradeInitializers/DiamondInit.sol";
import {Test} from "forge-std/Test.sol";
// import "../../lib/forge-std/src/interfaces/IERC20.sol";
import {IERC20Permit} from "../../contracts/interfaces/IERC20Permit.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ozEngine} from "../../contracts/facets/ozEngine.sol";
import "../../contracts/facets/DiamondCutFacet.sol";
import "../../contracts/facets/DiamondLoupeFacet.sol";
import "../../contracts/facets/OwnershipFacet.sol";
import "../../contracts/facets/MirrorExchange.sol";
import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";
import "../../contracts/facets/Pools.sol";
import "../../contracts/Diamond.sol";
import {IDiamondCut} from "../../contracts/interfaces/IDiamondCut.sol";
import {ozOracle} from "../../contracts/facets/ozOracle.sol"; 
import {ozBeacon} from "../../contracts/facets/ozBeacon.sol";
import {ozLoupe} from "../../contracts/facets/ozLoupe.sol";
import {ozToken} from "../../contracts/ozToken.sol";
import {wozToken} from "../../contracts/wozToken.sol";
import {
    Tokens,
    Dexes,
    Oracles,
    Infra,
    PauseContracts
} from "../../contracts/AppStorage.sol";
import {ReqOut, ReqIn} from "./AppStorageTests.sol";
import {ozCut} from "../../contracts/facets/ozCut.sol";
import {IRocketStorage, DAOdepositSettings} from "../../contracts/interfaces/IRocketPool.sol";

import {OZL} from "../../contracts/OZL.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {OZLproxy} from "../../contracts/OZLproxy.sol";
import {OZLadmin} from "../../contracts/facets/OZLadmin.sol";
import {OZLrewards} from "../../contracts/facets/OZLrewards.sol";

import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {OZLvesting} from "../../contracts/OZLvesting.sol";

// import "forge-std/console.sol";


contract Setup is Test {


    uint OWNER_PK = 123;
    uint ALICE_PK = 456;
    uint BOB_PK = 789;
    uint CHARLIE_PK = 101112;

    address internal owner;
    address internal alice;
    address internal bob;
    address internal charlie;
   
    enum Network {
        ARBITRUM,
        ETHEREUM
    }

    enum Quantity {
        SMALL,
        BIG
    }


    //ERC20s
    address internal usdtAddr;
    address internal usdcAddr;
    address internal wethAddr;
    address internal rEthAddr;
    address internal fraxAddr;
    address internal daiAddr;

    //For debugging purposes
    address internal usdcAddrImpl;
    address internal wethUsdPoolUni;
    address internal accessControlledOffchainAggregator; 
    address internal aeWETH;
    address internal rEthImpl;
    address internal feesCollectorBalancer;

    //Contracts
    address internal swapRouterUni;
    address internal ethUsdChainlink;
    address internal vaultBalancer; 
    address internal rEthWethPoolBalancer;
    address internal rEthEthChainlink;
    address internal tellorOracle;
    address internal weETHETHredStone;
    address internal weETHUSDredStone;
    //-- L1----
    address internal rocketPoolStorage;
    address internal rocketDAOProtocolSettingsDeposit;
    address internal uniFactory;
    address internal protocolGuildSplit;

    address internal testToken;
    address internal secondTestToken;
    address internal thirdTestToken;


    //Default diamond contracts and facets
    DiamondInit internal initDiamond;
    DiamondCutFacet internal cutFacet;
    OwnershipFacet internal ownership;
    Diamond internal ozDiamond;
    ozBeacon internal beacon;
    ozToken internal tokenOz;
    OZLrewards internal rewardsContract;
    wozToken internal tokenOzWrapped;

    //Ozel custom facets
    ozTokenFactory internal factory; 
    MirrorExchange internal mirrorEx;  
    Pools internal pools;
    ozEngine internal engine;
    ozOracle internal oracle;
    ozLoupe internal loupe;
    ozCut internal cutOz;

    ozIDiamond internal OZ;

    //OZL token
    OZL internal ozlLogic;
    OZLproxy internal ozlProxy;
    OZLadmin internal ozlAdmin;
    OZLvesting internal teamVesting;
    OZLvesting internal guildVesting;

    uint16 defaultSlippage = 50; //5 -> 0.05%; / 100 -> 1% / 50 -> 0.5%
    uint16 adminFee = 50;
    uint24 uniPoolFee = 500; //0.05 - 500 -- change this to uniFee05
    uint24 uniFee01 = 100;
    uint24 protocolFee = 1_500; //15%

    /**
     * How many contracts can be paused + value for non-paused contracts + the flag index
     * 0 - default value for non-paused facets
     * 1 - paused flag
     * 2 - entire system
     * 3 - all ozTokens and wozTokens
     * 4 - create new tokens (factory)
     * 5 - OZL
     */
    uint16 pauseIndexes = 6;

    uint internal constant _BASE = 18;

    uint internal constant SHARES_DECIMALS_OFFSET = 1e6;

    uint internal mainBlockNumber;
    uint internal secondaryBlockNumber;
    uint internal redStoneBlock;
    uint internal mainFork;
    uint internal redStoneFork;

    //OZL + team vesting
    uint campaignDuration = 365 days * 4; //126100000 secs
    uint communityAmount = 30_000_000 * 1e18;
    uint teamAmount = 14_000_000 * 1e18;
    uint guildAmount = 1_000_000 * 1e18;
    uint totalSupplyOZL = 100_000_000 * 1e18;
    uint startTimeVesting = 365 days * 3;
    uint durationTeamVesting = 365 days;
    address teamBeneficiary;

   

    /** FUNCTIONS **/ 
    function setUp() public {
        string memory network = _chooseNetwork(Network.ETHEREUM);
        redStoneFork = vm.createSelectFork(vm.rpcUrl(network), redStoneBlock);
        _runSetup();

        mainFork = vm.createSelectFork(vm.rpcUrl(network), mainBlockNumber);
        _runSetup();
    }

    function _chooseNetwork(Network chain_) private returns(string memory network) {
        if (chain_ == Network.ARBITRUM) {
            usdtAddr = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
            usdcAddr = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
            wethAddr = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
            usdcAddrImpl = 0x0f4fb9474303d10905AB86aA8d5A65FE44b6E04A;
            wethUsdPoolUni = 0xC6962004f452bE9203591991D15f6b388e09E8D0; //not used. Remove
            swapRouterUni = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            ethUsdChainlink = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
            vaultBalancer = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
            rEthAddr = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;
            rEthWethPoolBalancer = 0xadE4A71BB62bEc25154CFc7e6ff49A513B491E81;
            accessControlledOffchainAggregator = 0x3607e46698d218B3a5Cae44bF381475C0a5e2ca7;
            aeWETH = 0x8b194bEae1d3e0788A1a35173978001ACDFba668;
            rEthEthChainlink = 0xD6aB2298946840262FcC278fF31516D39fF611eF;
            rEthImpl = 0x3f770Ac673856F105b586bb393d122721265aD46;
            feesCollectorBalancer = 0xce88686553686DA562CE7Cea497CE749DA109f9F;
            fraxAddr = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F; //doesn't have a pool in Uniswap Arb, so it can only be used in L1.
            daiAddr = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
            rocketPoolStorage = address(0);
            uniFactory = address(0);

            network = "arbitrum";
            mainBlockNumber = 136177703;
        } else if (chain_ == Network.ETHEREUM) {
            usdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
            usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            usdcAddrImpl = 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF;
            wethUsdPoolUni = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; 
            swapRouterUni = 0xE592427A0AEce92De3Edee1F18E0157C05861564; //same as arb
            ethUsdChainlink = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
            vaultBalancer = 0xBA12222222228d8Ba445958a75a0704d566BF2C8; //same as arb
            rEthAddr = 0xae78736Cd615f374D3085123A210448E74Fc6393;
            rEthWethPoolBalancer = 0x1E19CF2D73a72Ef1332C882F20534B6519Be0276;
            accessControlledOffchainAggregator = address(0);
            aeWETH = address(0);
            rEthEthChainlink = 0x536218f9E9Eb48863970252233c8F271f554C2d0;
            rEthImpl = address(0);
            feesCollectorBalancer = address(0);
            fraxAddr = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
            daiAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
            rocketPoolStorage = 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46;
            rocketDAOProtocolSettingsDeposit = 0xac2245BE4C2C1E9752499Bcd34861B761d62fC27;
            uniFactory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
            tellorOracle = 0x8cFc184c877154a8F9ffE0fe75649dbe5e2DBEbf;
            weETHETHredStone = 0x8751F736E94F6CD167e8C5B97E245680FbD9CC36;
            weETHUSDredStone = 0xdDb6F90fFb4d3257dd666b69178e5B3c5Bf41136;
            protocolGuildSplit = 0x84af3D5824F0390b9510440B6ABB5CC02BB68ea1;

            network = "ethereum";
            mainBlockNumber = 18413618; //*18413614* - 18413618 - 18785221 (paused)
            secondaryBlockNumber = 18785221;
            redStoneBlock = 19154743;
        }
    }


    function _dealUnderlying(Quantity qnt_, bool isSecond_) internal returns(uint, uint, uint) {
        uint baseAmount = qnt_ == Quantity.SMALL ? 100 : 1_000_000;
        uint amountBob = baseAmount * 2;
        uint amountCharlie = baseAmount * 3;

        address[] memory tokens = new address[](isSecond_ ? 3 : 1);
        tokens[0] = testToken;
        
        if (isSecond_) {
            tokens[1] = secondTestToken;
            tokens[2] = thirdTestToken;
        }
        

        for (uint i=0; i<tokens.length; i++) {
            deal(tokens[i], alice, baseAmount * (10 ** IERC20Permit(tokens[i]).decimals()));
            deal(tokens[i], bob, amountBob * (10 ** IERC20Permit(tokens[i]).decimals()));
            deal(tokens[i], charlie, amountCharlie * (10 ** IERC20Permit(tokens[i]).decimals()));
        }

        return (baseAmount, amountBob, amountCharlie);
    }

    function _runSetup() internal {
        //*** SETS UP THE ERC20 TOKEN TO TEST WITH ****/
        testToken = daiAddr;
        secondTestToken = testToken == daiAddr ? usdcAddr : daiAddr;
        thirdTestToken = usdtAddr;
        //*** SETS UP THE ERC20 TOKEN TO TEST WITH ****/

        //Initial users config
        owner = vm.addr(OWNER_PK);
        alice = vm.addr(ALICE_PK);
        bob = vm.addr(BOB_PK);
        charlie = vm.addr(CHARLIE_PK);

        //Deploys diamond infra
        cutFacet = new DiamondCutFacet();
        ozDiamond = new Diamond(owner, address(cutFacet));
        initDiamond = new DiamondInit();

        //Deploys ozToken implementation contract for ozBeacon
        tokenOz = new ozToken();
        tokenOzWrapped = new wozToken();

        //Deploys facets
        loupe = new ozLoupe();
        ownership = new OwnershipFacet();
        mirrorEx = new MirrorExchange();
        factory = new ozTokenFactory();
        pools = new Pools();
        engine = new ozEngine();
        oracle = new ozOracle();

        address[] memory ozImplementations = new address[](2);
        ozImplementations[0] = address(tokenOz);
        ozImplementations[1] = address(tokenOzWrapped);

        beacon = new ozBeacon();
        cutOz = new ozCut();
        rewardsContract = new OZLrewards();

        //Deploys OZL token contracts
        _initOZLtokenPt1();

        //Create initial FacetCuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](11);
        cuts[0] = _createCut(address(loupe), 0);
        cuts[1] = _createCut(address(ownership), 1);
        cuts[2] = _createCut(address(mirrorEx), 2);
        cuts[3] = _createCut(address(factory), 3);
        cuts[4] = _createCut(address(pools), 4);
        cuts[5] = _createCut(address(engine), 5);
        cuts[6] = _createCut(address(oracle), 6);
        cuts[7] = _createCut(address(beacon), 7);
        cuts[8] = _createCut(address(cutOz), 8);
        cuts[9] = _createCut(address(ozlAdmin), 9);
        cuts[10] = _createCut(address(rewardsContract), 10);

        //Create init vars
        Tokens memory tokens = Tokens({
            weth: wethAddr,
            reth: rEthAddr,
            usdc: usdcAddr,
            usdt: usdtAddr
        });

        Dexes memory dexes = Dexes({
            swapRouterUni: swapRouterUni,
            vaultBalancer: vaultBalancer,
            rEthWethPoolBalancer: rEthWethPoolBalancer
        });

        Oracles memory oracles = Oracles({
            ethUsdChainlink: ethUsdChainlink,
            rEthEthChainlink: rEthEthChainlink,
            tellorOracle: tellorOracle,
            weETHETHredStone: weETHETHredStone,
            weETHUSDredStone: weETHUSDredStone
        });

        Infra memory infra = Infra({
            ozDiamond: address(ozDiamond),
            beacon: address(beacon),
            rocketPoolStorage: rocketPoolStorage,
            defaultSlippage: defaultSlippage,
            uniFee: uniPoolFee, //0.05 - 500,
            uniFee01: uniFee01,
            protocolFee: protocolFee,
            uniFactory: uniFactory,
            ozImplementations: ozImplementations,
            adminFee: adminFee,
            pauseIndexes: pauseIndexes
        });

        PauseContracts memory pause = PauseContracts({ //change this to PauseContracts, and everywhere
            ozDiamond: address(ozDiamond),
            ozBeacon: address(beacon),
            factory: address(factory),
            ozlProxy: address(ozlProxy)
        });

        bytes memory initData = abi.encodeWithSelector(
            initDiamond.init.selector, 
            tokens,
            dexes,
            oracles,
            infra,
            pause
        );
      
        OZ = ozIDiamond(address(ozDiamond));

        //Initialize diamond
        vm.startPrank(owner);
        OZ.diamondCut(cuts, address(initDiamond), initData);
        OZ.upgradeToBeacons(ozImplementations); //check if i can join this call with above ^

        _initOZLtokenPt2();

        //Sets labels
        _setLabels(); 

        vm.stopPrank();
    }


    function _createCut(
        address contractAddr_, 
        uint id_
    ) private view returns(IDiamondCut.FacetCut memory cut) {
        uint length;
        if (id_ == 1 || id_ == 7) {
            length = 2;
        } else if (id_ == 2 || id_ == 4) {
            length = 1;
        } else if (id_ == 3) {
            length = 3;
        } else if (id_ == 9) {
            length = 6; 
        } else if (id_ == 5) {
            length = 4;
        } else if (id_ == 10) {
            length = 11;
        } else if (id_ == 6) {
            length = 7;
        } else if (id_ == 0) {
            length = 17;
        } else if (id_ == 11) { //remove if not used
            length = 1;
        } else if (id_ == 8) {
            length = 9;
        }

        bytes4[] memory selectors = new bytes4[](length);

        if (id_ == 0) {
            selectors[0] = loupe.facets.selector;
            selectors[1] = loupe.facetFunctionSelectors.selector;
            selectors[2] = loupe.facetAddresses.selector;
            selectors[3] = loupe.facetAddress.selector;
            selectors[4] = loupe.supportsInterface.selector;
            selectors[5] = loupe.getDefaultSlippage.selector;
            selectors[6] = loupe.totalUnderlying.selector;
            selectors[7] = loupe.getProtocolFee.selector;
            selectors[8] = loupe.ozTokens.selector;
            selectors[9] = loupe.getLSDs.selector;
            selectors[10] = loupe.quoteAmountsIn.selector;
            selectors[11] = loupe.getMintData.selector;
            selectors[12] = loupe.quoteAmountsOut.selector;
            selectors[13] = loupe.getRedeemData.selector;
            selectors[14] = loupe.getAdminFee.selector;
            selectors[15] = loupe.getEnabledSwitch.selector;
            selectors[16] = loupe.getPausedContracts.selector;
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
            selectors[0] = engine.useUnderlying.selector;
            selectors[1] = engine.useOzTokens.selector;
            selectors[2] = engine.useOZL.selector;
            selectors[3] = engine.recicleOZL.selector;
        } else if (id_ == 6) {
            selectors[0] = oracle.rETH_ETH.selector;
            selectors[1] = oracle.getUnderlyingValue.selector;
            selectors[2] = oracle.ETH_USD.selector;
            selectors[3] = oracle.rETH_USD.selector;
            selectors[4] = oracle.chargeOZLfee.selector;
            selectors[5] = oracle.getLastRewards.selector;
            selectors[6] = oracle.setValuePerOzToken.selector;
        } else if (id_ == 7) {
            selectors[0] = beacon.getOzImplementations.selector;
            selectors[1] = beacon.upgradeToBeacons.selector;
        } else if (id_ == 8) {
            selectors[0] = cutOz.changeDefaultSlippage.selector;
            selectors[1] = cutOz.changeUniFee.selector;
            selectors[2] = cutOz.storeOZL.selector;
            selectors[3] = cutOz.changeAdminFeeRecipient.selector;
            selectors[4] = cutOz.changeProtocolFee.selector;
            selectors[5] = cutOz.changeAdminFee.selector;
            selectors[6] = cutOz.pause.selector;
            selectors[7] = cutOz.enableSwitch.selector;
            selectors[8] = cutOz.addPauseContract.selector;
        } else if (id_ == 9) {
            selectors[0] = ozlAdmin.getOZLlogic.selector;
            selectors[1] = ozlAdmin.getOZLadmin.selector;
            selectors[2] = ozlAdmin.changeOZLadmin.selector;
            selectors[3] = ozlAdmin.changeOZLlogic.selector;
            selectors[4] = ozlAdmin.changeOZLlogicAndCall.selector;
            selectors[5] = ozlAdmin.getOZL.selector;
        } else if (id_ == 10) {
            selectors[0] = rewardsContract.setRewardsDuration.selector;
            selectors[1] = rewardsContract.notifyRewardAmount.selector;
            selectors[2] = rewardsContract.lastTimeRewardApplicable.selector;
            selectors[3] = rewardsContract.rewardPerToken.selector;
            selectors[4] = rewardsContract.earned.selector;
            selectors[5] = rewardsContract.claimReward.selector;
            selectors[6] = rewardsContract.modifySupply.selector;
            selectors[7] = rewardsContract.startNewReciclingCampaign.selector;
            selectors[8] = rewardsContract.setRewardsDataExternally.selector;
            selectors[9] = rewardsContract.getRewardsData.selector;
            selectors[10] = rewardsContract.addToCirculatingSupply.selector;
        } 

        cut = IDiamondCut.FacetCut({
            facetAddress: contractAddr_,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
    }

    function _initOZLtokenPt1() private {
        ozlLogic = new OZL(); 
        vm.prank(owner);
        ozlAdmin = new OZLadmin();
    }


    function _initOZLtokenPt2() private {
        teamBeneficiary = owner;

        teamVesting = _createVestingWallet(teamBeneficiary);
        guildVesting = _createVestingWallet(protocolGuildSplit);
        
        bytes memory initData = abi.encodeWithSignature(
            'initialize(string,string,address,address,address,uint256,uint256,uint256,uint256)',
            "Ozel", "OZL", address(OZ), address(teamVesting), address(guildVesting),
            totalSupplyOZL, communityAmount, teamAmount, guildAmount
        );

        ozlProxy = new OZLproxy(
            address(ozlLogic), address(ozlAdmin), initData, address(OZ)
        );

        OZ.storeOZL(address(ozlProxy));
    }


    function _createVestingWallet(address beneficiary_) internal returns(OZLvesting) {
        return new OZLvesting(
            beneficiary_,
            uint64(startTimeVesting + block.timestamp),
            uint64(durationTeamVesting),
            address(ozlProxy),
            address(OZ)
        );
    }

    function _setLabels() private {
        vm.label(address(factory), "ozTokenFactory");
        vm.label(address(initDiamond), "DiamondInit");
        vm.label(address(engine), "ozEngine");
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
        vm.label(accessControlledOffchainAggregator, "AccessControlledOffchainAggregator");
        vm.label(aeWETH, "aeWETH");
        vm.label(rEthAddr, "rETH");
        vm.label(rEthImpl, "rETHimpl");
        vm.label(feesCollectorBalancer, "FeesCollectorBalancer");
        vm.label(address(oracle), "ozOracle");
        vm.label(address(beacon), "ozBeacon");
        vm.label(address(tokenOz), "ozTokenImplementation");
        vm.label(fraxAddr, "FRAX");
        vm.label(address(cutOz), "ozCut");
        vm.label(rocketPoolStorage, "rocketPoolStorage");
        vm.label(rEthEthChainlink, 'rEthEthChainlink');
        vm.label(daiAddr, 'DAI');
        vm.label(address(uniFactory), 'uniFactory');
        vm.label(address(ozlLogic), "OZL_Logic");
        vm.label(address(ozlProxy), "OZL_Proxy");
        vm.label(address(ozlAdmin), "OZL_Owner");
        vm.label(address(rewardsContract), "OZL_Rewards");
        vm.label(tellorOracle, "tellorOracle");
        vm.label(weETHETHredStone, "weETHETHredStone");
        vm.label(weETHUSDredStone, "weETHUSDredStone");
        vm.label(protocolGuildSplit, 'ProtocolGuild');
        vm.label(address(teamVesting), 'TeamVestingWallet');
        vm.label(address(guildVesting), 'GuildVestingWallet');
    }
}