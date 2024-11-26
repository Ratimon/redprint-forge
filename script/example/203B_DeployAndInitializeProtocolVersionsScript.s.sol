// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {SafeScript} from "@redprint-deploy/safe-management/SafeScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {ProtocolVersions, ProtocolVersion} from "@redprint-core/L1/ProtocolVersions.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployAndInitializeProtocolVersionsScript is DeployScript, SafeScript {
    using DeployerFunctions for IDeployer ;
    ProtocolVersions versions;
    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));

    function deploy() external returns (ProtocolVersions) {
        bytes32 _salt = DeployScript.implSalt();

        DeployOptions memory options = DeployOptions({salt:_salt});

        versions = deployer.deploy_ProtocolVersions("ProtocolVersions", options);

        Types.ContractSet memory contracts =  deployer.getProxiesUnstrict();

        contracts.ProtocolVersions = address(versions);
        ChainAssertions.checkProtocolVersions({ _contracts: contracts, _cfg: deployer.getConfig(), _isProxy: false });

        return versions;
    }

    function initialize() external {
        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();
        if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
            console.log("Pranking owner ...");
            vm.startPrank(owner);
            initializeProtocolVersions();
            vm.stopPrank();
        } else {
            console.log("Broadcasting ...");
            vm.startBroadcast(owner);

            initializeProtocolVersions();
            console.log("ProtocolVersions setted to : %s", address(versions));

            vm.stopBroadcast();
        }
    }

    function initializeProtocolVersions() public {
        console.log("Upgrading and initializing ProtocolVersions proxy");

        address proxyAdmin = deployer.mustGetAddress("ProxyAdmin");
        address safe = deployer.mustGetAddress("SystemOwnerSafe");

        address protocolVersionsProxy = deployer.mustGetAddress("ProtocolVersionsProxy");
        address protocolVersions = deployer.mustGetAddress("ProtocolVersions");

        address finalSystemOwner = deployer.getConfig().finalSystemOwner();
        uint256 requiredProtocolVersion = deployer.getConfig().requiredProtocolVersion();
        uint256 recommendedProtocolVersion = deployer.getConfig().recommendedProtocolVersion();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(protocolVersionsProxy),
            _implementation: protocolVersions,
            _innerCallData: abi.encodeCall(
                ProtocolVersions.initialize,
                (
                    finalSystemOwner,
                    ProtocolVersion.wrap(requiredProtocolVersion),
                    ProtocolVersion.wrap(recommendedProtocolVersion)
                )
            )
        });

        ProtocolVersions _versions = ProtocolVersions(protocolVersionsProxy);
        string memory version = _versions.version();
        console.log("ProtocolVersions version: %s", version);

        ChainAssertions.checkProtocolVersions({ _contracts: deployer.getProxiesUnstrict(), _cfg: deployer.getConfig(), _isProxy: true });
    }

}
