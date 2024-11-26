// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import { DeployConfig } from "@redprint-deploy/deployer/DeployConfig.s.sol";

import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {SystemConfigInterop} from "@redprint-core/L1/SystemConfigInterop.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeploySystemConfigInteropScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    SystemConfigInterop systemConfigInterop;

    function deploy() external returns (SystemConfigInterop) {
        DeployConfig cfg = deployer.getConfig();

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        systemConfigInterop = deployer.deploy_SystemConfigInterop("SystemConfig", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.SystemConfig = address(systemConfigInterop);
        ChainAssertions.checkSystemConfig({ _contracts: contracts, _cfg: cfg, _isProxy: false });

        return systemConfigInterop;
    }
}
