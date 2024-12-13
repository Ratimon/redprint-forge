// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {L1ERC721Bridge} from "@redprint-core/L1/L1ERC721Bridge.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployL1ERC721BridgeScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    L1ERC721Bridge l1ERC721Bridge;

    function deploy() external returns (L1ERC721Bridge) {
        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        l1ERC721Bridge = deployer.deploy_L1ERC721Bridge("L1ERC721Bridge", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.L1ERC721Bridge = address(l1ERC721Bridge);
        ChainAssertions.checkL1ERC721Bridge({ _contracts: contracts, _isProxy: false });

        return l1ERC721Bridge;
    }
}
