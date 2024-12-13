// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";
import {PreimageOracle} from "@redprint-core/cannon/PreimageOracle.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployPreimageOracleScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    PreimageOracle preimageOracle;

    function deploy() external returns (PreimageOracle) {
        DeployConfig cfg = deployer.getConfig();

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        preimageOracle = deployer.deploy_PreimageOracle("PreimageOracle", cfg.preimageOracleMinProposalSize(), cfg.preimageOracleChallengePeriod(), options);

        return preimageOracle;
    }
}
