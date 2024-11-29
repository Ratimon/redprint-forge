// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "@redprint-forge-std/Script.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {SafeScript} from "@redprint-deploy/safe-management/SafeScript.sol";
import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";

import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";

import {GameType} from "@redprint-core/dispute/lib/LibUDT.sol";
import { IDisputeGameFactory } from "@redprint-core/dispute/interfaces/IDisputeGameFactory.sol";
import { ISystemConfig } from "@redprint-core/L1/interfaces/ISystemConfig.sol";
import { ISuperchainConfig } from "@redprint-core/L1/interfaces/ISuperchainConfig.sol";

import {OptimismPortal2} from "@redprint-core/L1/OptimismPortal2.sol";


//  to do add more test
contract InitializeImplementationsScript is Script , SafeScript{
    IDeployer deployerProcedue;

    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));

    function run() public {

        deployerProcedue = getDeployer();
        deployerProcedue.setAutoSave(true);

        console.log("Initializing implementations");

        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();
        if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
            console.log("Pranking owner ...");
            vm.startPrank(owner);

            initializeOptimismPortal2();
            console.log("Pranking Stopped ...");
            
            vm.stopPrank();
        } else {
            console.log("Broadcasting ...");
            vm.startBroadcast(owner);

            initializeOptimismPortal2();
            console.log("Broadcasted");

            vm.stopBroadcast();
        }

    }


    function initializeOptimismPortal2() internal {
        console.log("Upgrading and initializing OptimismPortal2 proxy");

        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address optimismPortalProxy = deployerProcedue.mustGetAddress("OptimismPortalProxy");
        address optimismPortal2 = deployerProcedue.mustGetAddress("OptimismPortal2");
        address disputeGameFactoryProxy = deployerProcedue.mustGetAddress("DisputeGameFactoryProxy");
        address systemConfigProxy = deployerProcedue.mustGetAddress("SystemConfigProxy");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");

        DeployConfig cfg = deployerProcedue.getConfig();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,   
            _proxy: payable(optimismPortalProxy),
            _implementation: optimismPortal2,
            _innerCallData: abi.encodeCall(
                OptimismPortal2.initialize,
                    (
                        IDisputeGameFactory(disputeGameFactoryProxy),
                        ISystemConfig(systemConfigProxy),
                        ISuperchainConfig(superchainConfigProxy),
                        GameType.wrap(uint32(cfg.respectedGameType()))
                    )
            )
        });

        OptimismPortal2 portal = OptimismPortal2(payable(optimismPortalProxy));
        string memory version = portal.version();
        console.log("OptimismPortal2 version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();

        ChainAssertions.checkOptimismPortal2({ _contracts: proxies, _cfg: cfg, _isProxy: true });

    }

}
