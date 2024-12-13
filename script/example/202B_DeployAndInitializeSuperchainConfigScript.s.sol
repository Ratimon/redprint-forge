// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {SafeScript} from "@redprint-deploy/safe-management/SafeScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {Proxy} from "@redprint-core/universal/Proxy.sol";
import {SuperchainConfig} from "@redprint-core/L1/SuperchainConfig.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployAndInitializeSuperchainConfigScript is DeployScript, SafeScript {
    using DeployerFunctions for IDeployer ;
    SuperchainConfig superchainConfig;
    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));

    function deploy() external returns (SuperchainConfig) {
        bytes32 _salt = DeployScript.implSalt();

        DeployOptions memory options = DeployOptions({salt:_salt});

        superchainConfig = deployer.deploy_SuperchainConfig("SuperchainConfig", options);
        return superchainConfig;
    }

    function initialize() external {
        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();
        if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
            console.log("Pranking owner ...");
            vm.startPrank(owner);
            initializeSuperchainConfig();
            vm.stopPrank();
        } else {
            console.log("Broadcasting ...");
            vm.startBroadcast(owner);

            initializeSuperchainConfig();
            console.log("SuperchainConfig setted to : %s", address(superchainConfig));

            vm.stopBroadcast();
        }
    }

    function initializeSuperchainConfig() public {
        console.log("Upgrading and initializing SuperchainConfig");

        address payable superchainConfigProxy = deployer.mustGetAddress("SuperchainConfigProxy");
        address proxyAdmin = deployer.mustGetAddress("ProxyAdmin");
        address safe = deployer.mustGetAddress("SystemOwnerSafe");

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: superchainConfigProxy,
            _implementation:  address(superchainConfig),
            _innerCallData: abi.encodeCall(SuperchainConfig.initialize, ( deployer.getConfig().superchainConfigGuardian(), false))
        });

        ChainAssertions.checkSuperchainConfig({ _contracts: deployer.getProxiesUnstrict(), _cfg: deployer.getConfig(), _isPaused: false, _isProxy: true  });
    }
}
