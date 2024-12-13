// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@redprint-forge-std/Script.sol";
import {DeploySafeProxyScript} from "@scripts/101_DeploySafeProxyScript.s.sol";
// import {DeployGovernorScript} from "@scripts/111_DeployGoverner.s.sol";
import {SetupSuperchainScript} from "@scripts/200_SetupSuperchain.s.sol";
import {SetupOpchainScript} from "@scripts/400_SetupOpchain.s.sol";
import {SetupOpAltDAScript} from "@scripts/300_SetupOpAltDAScript.s.sol";

contract DeployAllScript is Script {
    function run() public {
        DeploySafeProxyScript safeDeployments = new DeploySafeProxyScript();
        // DeployGovernorScript governorDeployments = new DeployGovernorScript();
        //1) set up Safe Multisig
        safeDeployments.deploy();
        // governorDeployments.run();
        
        SetupSuperchainScript superchainSetups = new SetupSuperchainScript();
        superchainSetups.run();

        SetupOpAltDAScript opAltDASetups = new SetupOpAltDAScript();
        opAltDASetups.run();

        SetupOpchainScript opchainSetups = new SetupOpchainScript();
        opchainSetups.run();
    }
}
