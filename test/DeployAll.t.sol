// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "@redprint-forge-std/console.sol";

import {Test} from "@redprint-forge-std/Test.sol";

import {GnosisSafeProxy as SafeProxy} from "@redprint-safe-contracts/proxies/GnosisSafeProxy.sol";
import {AddressManager} from "@redprint-core/legacy/AddressManager.sol";
import {ProxyAdmin} from "@redprint-core/universal/ProxyAdmin.sol";

import {Proxy} from "@redprint-core/universal/Proxy.sol";
// import {SimpleStorage} from "./Proxy.t.sol";
import {L1ChugSplashProxy} from "@redprint-core/legacy/L1ChugSplashProxy.sol";
import {ResolvedDelegateProxy} from "@redprint-core/legacy/ResolvedDelegateProxy.sol";

import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";

import {DeployAllScript} from "@redprint-deploy/example/000_DeployAll.s.sol";
// import {DeployAllScript} from "@redprint-deploy/example/000_DeployAll2.s.sol";


contract DeployAll_Test is Test {
    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    address owner = vm.envOr("DEPLOYER", vm.addr(ownerPrivateKey));

    uint256 public staticTime;

    IDeployer deployerProcedue;

    SafeProxy safeProxy;
    AddressManager addressManager;
    ProxyAdmin admin;

    Proxy proxy;
    // SimpleStorage implementation;
    L1ChugSplashProxy chugsplash;
    ResolvedDelegateProxy resolved;

    function setUp() external {

        staticTime = block.timestamp;

        vm.warp({newTimestamp: staticTime + 1800000000});


        deployerProcedue = getDeployer();
        deployerProcedue.setAutoBroadcast(false);

        DeployAllScript allDeployments = new DeployAllScript();
        allDeployments.run();

        deployerProcedue.deactivatePrank();

    }


    function test_mock_succeeds() external {
        assertEq(true, true);
    }

}
