// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {DelayedWETH} from "@redprint-core/dispute/DelayedWETH.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployDelayedWETHScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    DelayedWETH delayedWETH;

    function deploy() external returns (DelayedWETH) {
        DeployConfig cfg = deployer.getConfig();

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        delayedWETH = deployer.deploy_DelayedWETH("DelayedWETH", cfg.faultGameWithdrawalDelay(), options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();
       
        contracts.DelayedWETH = address(delayedWETH);
        ChainAssertions.checkDelayedWETH({ _contracts: contracts, _cfg: cfg, _isProxy: false, _expectedOwner: address(0) });

        return delayedWETH;
    }
}
