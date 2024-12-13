// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, IDeployer} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {L1ChugSplashProxy} from "@redprint-core/legacy/L1ChugSplashProxy.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployL1StandardBridgeProxyScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    function deploy() external returns (L1ChugSplashProxy) {
        address proxyOwner = deployer.mustGetAddress("ProxyAdmin");

        return L1ChugSplashProxy(deployer.deploy_L1ChugSplashProxy("L1StandardBridgeProxy", proxyOwner ));
    }
}
