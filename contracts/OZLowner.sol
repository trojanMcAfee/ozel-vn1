// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;


import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import {AppStorage} from "./AppStorage.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


contract OZLowner is ProxyAdmin {

    AppStorage private s;


    function getOZLlogic() external view returns(address) {
        return getProxyImplementation(ITransparentUpgradeableProxy(s.ozlProxy));
    }

    function getOZLowner() external view returns(address) {
        return getProxyAdmin(ITransparentUpgradeableProxy(s.ozlProxy));
    }

    function changeOZLowner() external {}


}