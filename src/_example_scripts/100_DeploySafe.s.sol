// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript, IDeployer} from "@redprint/deployer/DeployScript.sol";
import {DeployerFunctions} from "@redprint/deployer/DeployerFunctions.sol";

import {SafeProxyFactory} from "@safe-contracts/proxies/SafeProxyFactory.sol";
import {Safe} from "@safe-contracts/Safe.sol";
import {SafeProxy} from "@safe-contracts/proxies/SafeProxy.sol";

contract DeploySafeScript is DeployScript {
    using DeployerFunctions for IDeployer;

    address owner;

    function deploy()
        external
        returns (SafeProxyFactory safeProxyFactory_, Safe safeSingleton_, SafeProxy safeProxy_)
    {
        // These are the standard create2 deployed contracts. First we'll check if they are deployed,
        // if not we'll deploy new ones, though not at these addresses.
        address safeProxyFactory = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
        address safeSingleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;

        safeProxyFactory.code.length == 0
            ? safeProxyFactory_ = SafeProxyFactory(deployer.deploy_SafeProxyFactory("SafeProxyFactory"))
            : safeProxyFactory_ = SafeProxyFactory(safeProxyFactory);

        safeSingleton.code.length == 0
            ? safeSingleton_ = Safe(deployer.deploy_Safe("SafeSingleton"))
            : safeSingleton_ = Safe(payable(safeSingleton));

        string memory mnemonic = vm.envString("MNEMONIC");
        uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        owner = vm.envOr("DEPLOYER", vm.addr(ownerPrivateKey));

        safeProxy_ = SafeProxy(
            deployer.deploy_SystemOwnerSafe("SystemOwnerSafe", "SafeProxyFactory", "SafeSingleton", address(owner))
        );
    }
}
