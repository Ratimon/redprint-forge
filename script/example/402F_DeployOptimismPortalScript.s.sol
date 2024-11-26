// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {OptimismPortal} from "@redprint-core/L1/OptimismPortal.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployOptimismPortalScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    OptimismPortal optimismPortal;

    function deploy() external returns (OptimismPortal) {
        DeployConfig cfg = deployer.getConfig();

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        optimismPortal = deployer.deploy_OptimismPortal("OptimismPortal", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.OptimismPortal = address(optimismPortal);
        ChainAssertions.checkOptimismPortal({ _contracts: contracts, _cfg: cfg, _isProxy: false });

        return optimismPortal;
    }
}
