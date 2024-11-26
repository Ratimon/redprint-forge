// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, IDeployer} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {Proxy} from "@redprint-core/universal/Proxy.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployDelayedWETHProxyScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    function deploy() external returns (Proxy) {
        address proxyOwner = deployer.mustGetAddress("ProxyAdmin");

        return Proxy(deployer.deploy_ERC1967Proxy("DelayedWETHProxy", proxyOwner));
    }
}