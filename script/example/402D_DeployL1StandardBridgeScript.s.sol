// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {L1StandardBridge} from "@redprint-core/L1/L1StandardBridge.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployL1StandardBridgeScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    L1StandardBridge l1StandardBridge;

    function deploy() external returns (L1StandardBridge) {
        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        l1StandardBridge = deployer.deploy_L1StandardBridge("L1StandardBridge", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.L1StandardBridge = address(l1StandardBridge);
        ChainAssertions.checkL1StandardBridge({ _contracts: contracts, _isProxy: false });

        return l1StandardBridge;
    }
}
