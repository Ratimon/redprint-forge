// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {DisputeGameFactory} from "@redprint-core/dispute/DisputeGameFactory.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployDisputeGameFactoryScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    DisputeGameFactory disputeGameFactory;

    function deploy() external returns (DisputeGameFactory) {
        bytes32 _salt = DeployScript.implSalt();

        DeployOptions memory options = DeployOptions({salt:_salt});
        disputeGameFactory = deployer.deploy_DisputeGameFactory("DisputeGameFactory", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.DisputeGameFactory = address(disputeGameFactory);
        ChainAssertions.checkDisputeGameFactory({ _contracts: contracts, _expectedOwner: address(0), _isProxy: false });

        return disputeGameFactory;
    }
}
