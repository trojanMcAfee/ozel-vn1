// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


// import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ProxyAdmin} from "../ProxyAdmin.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {AppStorage} from "../AppStorage.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "forge-std/console.sol";


contract OZLadmin is ProxyAdmin {

    AppStorage private s;


    function getOZL() external view returns(address) {
        return s.ozlProxy;
    }

    function getOZLlogic() external view returns(address) {
        return _getProxyImplementation(ITransparentUpgradeableProxy(s.ozlProxy));
    }

    function getOZLadmin() external view returns(address) {
        return _getProxyAdmin(ITransparentUpgradeableProxy(s.ozlProxy));
    }

    function changeOZLadmin(address newAdmin_) external {
        LibDiamond.enforceIsContractOwner();
        _changeProxyAdmin(ITransparentUpgradeableProxy(s.ozlProxy), newAdmin_);
    }

    function changeOZLlogic(address newLogic_) external {
        LibDiamond.enforceIsContractOwner();
        _upgrade(ITransparentUpgradeableProxy(s.ozlProxy), newLogic_);
    }

    function changeOZLlogicAndCall(address newLogic_, bytes memory data_) external payable {
        LibDiamond.enforceIsContractOwner();
        _upgradeAndCall(ITransparentUpgradeableProxy(s.ozlProxy), newLogic_, data_);
    }
}