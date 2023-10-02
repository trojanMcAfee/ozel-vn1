// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";
import {ozIDiamond, FacetCut, FacetCutAction} from "../../interfaces/ozIDiamond.sol";
import {InitUpgradeV2} from "../../contracts/InitUpgradeV2.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "../../lib/forge-std/src/interfaces/IERC20.sol";
import {ROImodule} from "../../contracts/facets/ROImodule.sol";
import {ozLoupeFacetV2} from "../../contracts/facets/ozLoupeFacetV2.sol";

import "forge-std/console.sol";


contract Setup is Test {

    address internal ozDiamond = 0x7D1f13Dd05E6b0673DC3D0BFa14d40A74Cfa3EF2;
    address internal usdtAddr = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal usdcAddr = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal deployer = 0xe738696676571D9b74C81716E4aE797c2440d306;
    address internal alice;

    IERC20 internal USDC = IERC20(usdcAddr);

    ozIDiamond internal OZL;
    InitUpgradeV2 internal initUpgrade;
    ozTokenFactory internal factory; 
    ROImodule internal roiMod; 
    ozLoupeFacetV2 internal loupeV2;


    //------------------

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrum"), 136177703);
        _runSetup();
    }


    function _runSetup() internal {
        address[] memory registry = new address[](1);
        registry[0] = usdtAddr;

        factory = new ozTokenFactory();
        initUpgrade = new InitUpgradeV2();
        roiMod = new ROImodule();
        loupeV2 = new ozLoupeFacetV2();

        OZL = ozIDiamond(ozDiamond);

        bytes memory data = abi.encodeWithSelector(
            initUpgrade.init.selector, 
            registry,
            ozDiamond
        );

        FacetCut[] memory cuts = new FacetCut[](3);
        cuts[0] = _createCut(address(factory), 0);
        cuts[1] = _createCut(address(roiMod), 1);
        cut[2] = _createCut(address(loupeV2), 2);

        vm.prank(deployer);
        OZL.diamondCut(cuts, address(initUpgrade), data);

        alice = makeAddr("alice");
        deal(usdcAddr, alice, 1500 * 1e6);

        _setLabels();
    }


    function _createCut(
        address contractAddr_, 
        uint id_
    ) private view returns(FacetCut memory cut) {
        uint length;
        if (id_ == 0 || id_ == 1 || id_ == 2) {
            length = 1;
        }

        bytes4[] memory selectors = new bytes4[](length);

        if (id_ == 0) {
            selectors[0] = factory.createOzToken.selector;
        } else if (id_ == 1) {
            selectors[0] = roiMod.useUnderlying.selector;
        } else if (id_ == 2) {
            selectors[0] = loupeV2.getDiamondAddr.selector;
        }

        cut = FacetCut({
            facetAddress: contractAddr_,
            action: FacetCutAction.Add,
            functionSelectors: selectors
        });
    }

    function _setLabels() private {
        vm.label(address(factory), "ozTokenFactory");
        vm.label(address(initUpgrade), "InitUpgradeV2");
        vm.label(address(roiMod), "ROImodule");
        vm.label(alice, "alice");
        vm.label(usdcAddr, "USDC");
        vm.label(usdtAddr, "USDT");
        vm.label(ozDiamond, "ozDiamond");
        vm.label(address(loupeV2), "ozLoupeFacetV2");
    }


}