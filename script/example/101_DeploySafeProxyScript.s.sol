// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, IDeployer} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {GnosisSafe as Safe} from "@redprint-safe-contracts/GnosisSafe.sol";
import {GnosisSafeProxy as SafeProxy} from "@redprint-safe-contracts/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory as SafeProxyFactory} from "@redprint-safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import {console} from "@redprint-forge-std/console.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeploySafeProxyScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));

    function deploy()
        external
        returns (SafeProxyFactory safeProxyFactory_, Safe safeSingleton_, SafeProxy safeProxy_)
    {
        console.log("Setup Governance ... ");
        address safeProxyFactory = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
        address safeSingleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;

       safeProxyFactory.code.length == 0
            ? safeProxyFactory_ = SafeProxyFactory(deployer.deploy_SafeProxyFactory("SafeProxyFactory"))
            : safeProxyFactory_ = SafeProxyFactory(safeProxyFactory);

        safeSingleton.code.length == 0
            ? safeSingleton_ = Safe(deployer.deploy_Safe("SafeSingleton"))
            : safeSingleton_ = Safe(payable(safeSingleton));

        safeProxy_ = SafeProxy(
            deployer.deploy_SystemOwnerSafe("SystemOwnerSafe", "SafeProxyFactory", "SafeSingleton", address(owner), DeployScript.implSalt())
        );
    }
}
