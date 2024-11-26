// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import { DeployConfig } from "@redprint-deploy/deployer/DeployConfig.s.sol";

import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {SystemConfig} from "@redprint-core/L1/SystemConfig.sol";
// import {SystemConfigInterop} from "@redprint-core/universal/SystemConfigInterop.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeploySystemConfigScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    SystemConfig systemConfig;
    // SystemConfigInterop systemConfigInterop;

    function deploy() external returns (SystemConfig) {
        DeployConfig cfg = deployer.getConfig();

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        systemConfig = deployer.deploy_SystemConfig("SystemConfig", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.SystemConfig = address(systemConfig);
        ChainAssertions.checkSystemConfig({ _contracts: contracts, _cfg: cfg, _isProxy: false });

        return systemConfig;
    }
}
