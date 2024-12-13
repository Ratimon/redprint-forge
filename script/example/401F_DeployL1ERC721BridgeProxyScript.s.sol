// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, IDeployer} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {Proxy} from "@redprint-core/universal/Proxy.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployL1ERC721BridgeProxyScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    function deploy() external returns (Proxy) {
        address proxyOwner = deployer.mustGetAddress("ProxyAdmin");

        return Proxy(deployer.deploy_ERC1967Proxy("L1ERC721BridgeProxy", proxyOwner));
    }
}