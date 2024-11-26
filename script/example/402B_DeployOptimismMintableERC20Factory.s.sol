// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {OptimismMintableERC20Factory} from "@redprint-core/universal/OptimismMintableERC20Factory.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployOptimismMintableERC20FactoryScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    OptimismMintableERC20Factory factory;

    function deploy() external returns (OptimismMintableERC20Factory) {
        bytes32 _salt = DeployScript.implSalt();

        DeployOptions memory options = DeployOptions({salt:_salt});
        factory = deployer.deploy_OptimismMintableERC20Factory("OptimismMintableERC20Factory", options);
        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.OptimismMintableERC20Factory = address(factory);
        ChainAssertions.checkOptimismMintableERC20Factory({ _contracts: contracts, _isProxy: false });

        return factory;
    }
}
