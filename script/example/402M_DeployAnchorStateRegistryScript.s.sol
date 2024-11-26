// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {IDisputeGameFactory} from "@redprint-core/dispute/interfaces/IDisputeGameFactory.sol";
import {AnchorStateRegistry} from "@redprint-core/dispute/AnchorStateRegistry.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployAnchorStateRegistryScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    AnchorStateRegistry anchorStateRegistry;

    function deploy() external returns (AnchorStateRegistry) {
        address disputeGameFactory = deployer.mustGetAddress("DisputeGameFactory");

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        anchorStateRegistry = deployer.deploy_AnchorStateRegistry("AnchorStateRegistry", IDisputeGameFactory(disputeGameFactory), options);

        return anchorStateRegistry;
    }
}
