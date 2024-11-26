// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {L2OutputOracle} from "@redprint-core/L1/L2OutputOracle.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployL2OutputOracleScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    L2OutputOracle l2OutputOracle;

    function deploy() external returns (L2OutputOracle) {
        DeployConfig cfg = deployer.getConfig();

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        l2OutputOracle = deployer.deploy_L2OutputOracle("L2OutputOracle", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.L2OutputOracle = address(l2OutputOracle);
        ChainAssertions.checkL2OutputOracle({ _contracts: contracts, _cfg: cfg, _l2OutputOracleStartingTimestamp: 0, _isProxy: false });

        return l2OutputOracle;
    }
}
