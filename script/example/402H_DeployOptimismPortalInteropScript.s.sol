// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {OptimismPortalInterop} from "@redprint-core/L1/OptimismPortalInterop.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployOptimismPortalInteropScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    OptimismPortalInterop optimismPortal;

    function deploy() external returns (OptimismPortalInterop) {
        DeployConfig cfg = deployer.getConfig();
        // Could also verify this inside DeployConfig but doing it here is a bit more reliable.
        require(
            uint32(cfg.respectedGameType()) == cfg.respectedGameType(), "Deploy: respectedGameType must fit into uint32"
        );

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        optimismPortal = deployer.deploy_OptimismPortalInterop("OptimismPortal2", cfg.proofMaturityDelaySeconds(), cfg.disputeGameFinalityDelaySeconds(), options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.OptimismPortal2 = address(optimismPortal);
        ChainAssertions.checkOptimismPortal2({ _contracts: contracts, _cfg: cfg, _isProxy: false });

        return optimismPortal;
    }
}
