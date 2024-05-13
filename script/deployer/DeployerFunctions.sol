// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from "@forge-std/console2.sol";

import {IDeployer} from "@script/deployer/Deployer.sol";
import {DefaultDeployerFunction, DeployOptions} from "@script/deployer/DefaultDeployerFunction.sol";

import {SafeProxy} from "@safe-contracts/proxies/SafeProxy.sol";
import {SafeProxyFactory} from "@safe-contracts/proxies/SafeProxyFactory.sol";
import {Safe} from "@safe-contracts/Safe.sol";

import {AddressManager} from "src/legacy/AddressManager.sol";
import {ProxyAdmin} from "src/universal/ProxyAdmin.sol";

string constant Artifact_SafeProxyFactory = "SafeProxyFactory.sol:SafeProxyFactory";
string constant Artifact_Safe = "Safe.sol:Safe";

string constant Artifact_AddressManager = "AddressManager.sol:AddressManager";
string constant Artifact_ProxyAdmin = "ProxyAdmin.sol:ProxyAdmin";

library DeployerFunctions {
    function deploy_SafeProxyFactory(IDeployer deployer, string memory name) internal returns (SafeProxyFactory) {
        console.log("Deploying SafeProxyFactory");
        bytes memory args = abi.encode();
        return SafeProxyFactory(DefaultDeployerFunction.deploy(deployer, name, Artifact_SafeProxyFactory, args));
    }

    function deploy_SafeProxyFactory(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (SafeProxyFactory)
    {
        console.log("Deploying SafeProxyFactory");
        bytes memory args = abi.encode();
        return
            SafeProxyFactory(DefaultDeployerFunction.deploy(deployer, name, Artifact_SafeProxyFactory, args, options));
    }

    function deploy_Safe(IDeployer deployer, string memory name) internal returns (Safe) {
        console.log("Deploying Safe");
        bytes memory args = abi.encode();
        return Safe(DefaultDeployerFunction.deploy(deployer, name, Artifact_Safe, args));
    }

    function deploy_Safe(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (Safe)
    {
        console.log("Deploying Safe");
        bytes memory args = abi.encode();
        return Safe(DefaultDeployerFunction.deploy(deployer, name, Artifact_Safe, args, options));
    }

    function deploy_SystemOwnerSafe(
        IDeployer deployer,
        string memory name,
        string memory safeProxyFactoryName,
        string memory safeSingletonyName,
        address owner
    ) internal returns (SafeProxy) {
        SafeProxyFactory safeProxyFactory = SafeProxyFactory(deployer.mustGetAddress(safeProxyFactoryName));
        Safe safeSingleton = Safe(deployer.mustGetAddress(safeSingletonyName));

        address[] memory signers = new address[](1);
        signers[0] = owner;

        bytes memory initData = abi.encodeWithSelector(
            Safe.setup.selector, signers, 1, address(0), hex"", address(0), address(0), 0, address(0)
        );

        SafeProxy safeProxy = safeProxyFactory.createProxyWithNonce(address(safeSingleton), initData, block.timestamp);
        deployer.save(name, address(safeProxy));
        console.log("New SystemOwnerSafe deployed at %s", address(safeProxy));

        return safeProxy;
    }

    function deploy_AddressManager(IDeployer deployer, string memory name) internal returns (AddressManager) {
        bytes memory args = abi.encode();
        return AddressManager(DefaultDeployerFunction.deploy(deployer, name, Artifact_AddressManager, args));
    }

    function deploy_ProxyAdmin(IDeployer deployer, string memory name, address _owner) internal returns (ProxyAdmin) {
        bytes memory args = abi.encode(_owner);
        return ProxyAdmin(DefaultDeployerFunction.deploy(deployer, name, Artifact_ProxyAdmin, args));
    }

    function deploy_ProxyAdmin(IDeployer deployer, string memory name, address _owner, DeployOptions memory options)
        internal
        returns (ProxyAdmin)
    {
        bytes memory args = abi.encode(_owner);
        return ProxyAdmin(DefaultDeployerFunction.deploy(deployer, name, Artifact_ProxyAdmin, args, options));
    }
}
