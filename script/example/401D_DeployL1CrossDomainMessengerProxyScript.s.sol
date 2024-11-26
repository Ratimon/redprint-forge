// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, IDeployer} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {AddressManager} from "@redprint-core/legacy/AddressManager.sol";
import {ResolvedDelegateProxy} from "@redprint-core/legacy/ResolvedDelegateProxy.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployL1CrossDomainMessengerProxyScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    function deploy() external returns (ResolvedDelegateProxy) {
        address addressManager = deployer.mustGetAddress("AddressManager");

        return ResolvedDelegateProxy(deployer.deploy_ResolvedDelegateProxy("L1CrossDomainMessengerProxy", addressManager, "OVM_L1CrossDomainMessenger" ));
    }
}