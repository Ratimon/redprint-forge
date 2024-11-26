// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {IPreimageOracle} from "@redprint-core/cannon/interfaces/IPreimageOracle.sol";
import {MIPS} from "@redprint-core/cannon/MIPS.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployMIPSScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    MIPS mips;

    function deploy() external returns (MIPS) {
        address preimageOracle = deployer.mustGetAddress("PreimageOracle");

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        mips = deployer.deploy_MIPS("Mips", IPreimageOracle(preimageOracle), options);

        return mips;
    }
}
