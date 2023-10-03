// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import  "../../contracts/facets/ozTokenFactory.sol";
import "../../interfaces/ozIDiamond.sol";
import "../../contracts/upgradeInitializers/DiamondInit.sol";
import {Test} from "forge-std/Test.sol";
import "../../lib/forge-std/src/interfaces/IERC20.sol";
import "../../contracts/facets/ROImodule.sol";

import "../../contracts/facets/DiamondCutFacet.sol";
import "../../contracts/facets/DiamondLoupeFacet.sol";
import "../../contracts/facets/OwnershipFacet.sol";
import "../../contracts/facets/MirrorExchange.sol";
import "../../contracts/facets/ozTokenFactory.sol";
import "../../contracts/facets/Pools.sol";
import "../../contracts/facets/ROImodule.sol";
import "../../contracts/Diamond.sol";

import "forge-std/console.sol";


contract Setup is Test {

    // address internal ozDiamond = 0x7D1f13Dd05E6b0673DC3D0BFa14d40A74Cfa3EF2;
    address internal usdtAddr = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal usdcAddr = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal wethAddr = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // address internal deployer = 0xe738696676571D9b74C81716E4aE797c2440d306;
    address internal alice;

    IERC20 internal USDC = IERC20(usdcAddr);

    ozIDiamond internal OZL;
    DiamondInit internal initDiamond;
    ozTokenFactory internal factory; 
    ROImodule internal roiMod; 
    //------

    DiamondCutFacet internal cutFacet;
    Diamond internal ozDiamond;
    DiamondLoupeFacet internal loupe;
    OwnershipFacet internal ownership;
    MirrorExchange internal mirrorEx;  
    ozTokenFactory internal factory;
    Pools internal pools;
    ROImodule internal roi;


    /** FUNCTIONS **/
    
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrum"), 136177703);
        _runSetup();
    }


    function _runSetup() internal {
        alice = makeAddr("alice");

        //Deploys diamond infra
        cutFacet = new DiamondCutFacet();
        ozDiamond = new Diamond(alice, address(cutFacet));
        initDiamond = new DiamondInit();

        //Deploys facets
        loupe = new DiamondLoupeFacet();
        ownership = new OwnershipFacet();
        mirrorEx = new MirrorExchange();
        factory = new ozTokenFactory();
        pools = new Pools();
        roi = new ROImodule();

        FacetCut[] memory cuts = new FacetCut[]();
        cuts[0] = _createCut(address(loupe), 0);
        //deploying initially the diamond ***


        //--------
        address[] memory registry = new address[](1);
        registry[0] = usdtAddr;

        factory = new ozTokenFactory();
        roiMod = new ROImodule();

        // OZL = ozIDiamond(ozDiamond);

        bytes memory data = abi.encodeWithSelector(
            initDiamond.init.selector, 
            registry,
            address(roiMod)
        );

        FacetCut[] memory cuts = new FacetCut[](2);
        cuts[0] = _createCut(address(factory), 0);
        cuts[1] = _createCut(address(roiMod), 1);

        vm.prank(deployer);
        OZL.diamondCut(cuts, address(initDiamond), data);

        alice = makeAddr("alice");
        deal(usdcAddr, alice, 1500 * 1e6);

        _setLabels();
    }


    function _createCut(
        address contractAddr_, 
        uint id_
    ) private view returns(FacetCut memory cut) {
        uint length;
        if (id_ == 0 || id_ == 1) {
            length = 1;
        }

        bytes4[] memory selectors = new bytes4[](length);

        if (id_ == 0) {
            selectors[0] = factory.createOzToken.selector;
        } else if (id_ == 1) {
            selectors[0] = roiMod.useUnderlying.selector;
        } 

        cut = FacetCut({
            facetAddress: contractAddr_,
            action: FacetCutAction.Add,
            functionSelectors: selectors
        });
    }

    function _setLabels() private {
        vm.label(address(factory), "ozTokenFactory");
        vm.label(address(initDiamond), "DiamondInit");
        vm.label(address(roiMod), "ROImodule");
        vm.label(alice, "alice");
        vm.label(usdcAddr, "USDC");
        vm.label(usdtAddr, "USDT");
        vm.label(ozDiamond, "ozDiamond");
    }


}