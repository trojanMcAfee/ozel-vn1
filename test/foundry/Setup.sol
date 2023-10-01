// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ozTokenFactory} from "../../contracts/facets/ozTokenFactory.sol";
import {ozIDiamond, FacetCut, FacetCutAction} from "../../interfaces/ozIDiamond.sol";
import {InitUpgradeV2} from "../../contracts/InitUpgradeV2.sol";
import {Test} from "forge-std/Test.sol";


contract Setup is Test {

    ozTokenFactory internal factory; 

    address internal diamond = 0x7D1f13Dd05E6b0673DC3D0BFa14d40A74Cfa3EF2;
    address internal usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal deployer = 0xe738696676571D9b74C81716E4aE797c2440d306;

    ozIDiamond internal ozl;
    InitUpgradeV2 internal initUpgrade;


    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arbitrum"), 136177703);
        _runSetup();
    }


    function _runSetup() internal {
        address[] memory registry = new address[](1);
        registry[0] = usdt;

        factory = new ozTokenFactory();
        initUpgrade = new InitUpgradeV2();

        ozl = ozIDiamond(diamond);

        bytes memory data = abi.encodeWithSelector(
            initUpgrade.init.selector, 
            registry
        );

        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = _createCut(address(factory), 0);

        vm.prank(deployer);
        ozl.diamondCut(cuts, address(initUpgrade), data);

        _setLabels();

    }


    function _createCut(
        address contractAddr_, 
        uint id_
    ) private view returns(FacetCut memory cut) {
        uint length;
        if (id_ == 0) {
            length = 1;
        }

        bytes4[] memory selectors = new bytes4[](length);

        if (id_ == 0) {
            selectors[0] = factory.createOzToken.selector;
        }

        cut = FacetCut({
            facetAddress: contractAddr_,
            action: FacetCutAction.Add,
            functionSelectors: selectors
        });
    }

    function _setLabels() private {
        vm.label(address(factory), "factory_c");
        vm.label(address(initUpgrade), "initUpgrade_c");
    }

}