// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "@redprint-forge-std/Script.sol";
import {console} from "@redprint-forge-std/console.sol";
import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployDataAvailabilityChallengeProxyScript} from "@redprint-deploy/example/301A_DeployDataAvailabilityChallengeProxyScript.s.sol";
import {DeployAndInitializeDataAvailabilityChallengeScript} from "@redprint-deploy/example/301B_DeployAndInitializeDataAvailabilityChallengeScript.s.sol";

contract SetupOpAltDAScript is Script {
    IDeployer deployerProcedue;

    function run() public {
        deployerProcedue = getDeployer();
        deployerProcedue.setAutoSave(true);

        console.log("Setup Op Alt DA ... ");

        DeployDataAvailabilityChallengeProxyScript dataAvailabilityChallengeProxyDeployments = new DeployDataAvailabilityChallengeProxyScript();
        DeployAndInitializeDataAvailabilityChallengeScript dataAvailabilityChallengeDeployments = new DeployAndInitializeDataAvailabilityChallengeScript();

        dataAvailabilityChallengeProxyDeployments.deploy();
        dataAvailabilityChallengeDeployments.deploy();
        dataAvailabilityChallengeDeployments.initialize();


        console.log("DataAvailabilityChallengeProxy at: ", deployerProcedue.getAddress("DataAvailabilityChallengeProxy"));
        console.log("DataAvailabilityChallenge at: ", deployerProcedue.getAddress("DataAvailabilityChallenge"));

    }
}
