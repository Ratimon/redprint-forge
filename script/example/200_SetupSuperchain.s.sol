// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@redprint-forge-std/Script.sol";
import {console} from "@redprint-forge-std/console.sol";
import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployAddressManagerScript} from "@scripts/201A_DeployAddressManagerScript.s.sol";
import {DeployAndSetupProxyAdminScript} from "@scripts/201B_DeployAndSetupProxyAdminScript.s.sol";
import {DeploySuperchainConfigProxyScript} from "@scripts/202A_DeploySuperchainConfigProxyScript.s.sol";
import {DeployAndInitializeSuperchainConfigScript} from "@scripts/202B_DeployAndInitializeSuperchainConfigScript.s.sol";
import {DeployProtocolVersionsProxyScript} from "@scripts/203A_DeployProtocolVersionsProxyScript.s.sol";
import {DeployAndInitializeProtocolVersionsScript} from "@scripts/203B_DeployAndInitializeProtocolVersionsScript.s.sol";

contract SetupSuperchainScript is Script {
    IDeployer deployerProcedue;

    function run() public {
        deployerProcedue = getDeployer();
        deployerProcedue.setAutoSave(true);
        DeployAddressManagerScript addressManagerDeployments = new DeployAddressManagerScript();
        DeployAndSetupProxyAdminScript proxyAdminDeployments = new DeployAndSetupProxyAdminScript();

        DeploySuperchainConfigProxyScript superchainConfigProxyDeployments = new DeploySuperchainConfigProxyScript();
        DeployAndInitializeSuperchainConfigScript superchainConfigDeployments = new DeployAndInitializeSuperchainConfigScript();

        DeployProtocolVersionsProxyScript protocolVersionsProxyDeployments = new DeployProtocolVersionsProxyScript();
        DeployAndInitializeProtocolVersionsScript protocolVersionsDeployments = new DeployAndInitializeProtocolVersionsScript();

        // Deploy a new ProxyAdmin and AddressManager
        addressManagerDeployments.deploy();
        proxyAdminDeployments.deploy();
        proxyAdminDeployments.initialize();

        // Deploy the SuperchainConfigProxy
        superchainConfigProxyDeployments.deploy();
        superchainConfigDeployments.deploy();
        superchainConfigDeployments.initialize();

        // Deploy the ProtocolVersionsProxy
        protocolVersionsProxyDeployments.deploy();
        protocolVersionsDeployments.deploy();
        protocolVersionsDeployments.initialize();


        console.log("AddressManager at: ", deployerProcedue.getAddress("AddressManager"));
        console.log("ProxyAdmin at: ", deployerProcedue.getAddress("ProxyAdmin"));
        console.log("SuperchainConfigProxy at: ", deployerProcedue.getAddress("SuperchainConfigProxy"));
        console.log("SuperchainConfig at: ", deployerProcedue.getAddress("SuperchainConfig"));
        console.log("ProtocolVersionsProxy at: ", deployerProcedue.getAddress("ProtocolVersionsProxy"));

        //  to do :
        // deployerProcedue.save("SuperchainConfig", deployerProcedue.getAddress("SuperchainConfig"));

    }
}
