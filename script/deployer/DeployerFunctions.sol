// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from "@forge-std/console2.sol";
import { Vm } from "@forge-std/Vm.sol";

import {IDeployer} from "@script/deployer/Deployer.sol";
import {DefaultDeployerFunction, DeployOptions} from "@script/deployer/DefaultDeployerFunction.sol";

import { EIP1967Helper } from "@main/universal/EIP1967Helper.sol";

import {SafeProxy} from "@safe-contracts/proxies/SafeProxy.sol";
import {SafeProxyFactory} from "@safe-contracts/proxies/SafeProxyFactory.sol";
import {Safe} from "@safe-contracts/Safe.sol";

import {AddressManager} from "@main/legacy/AddressManager.sol";
import {ProxyAdmin} from "@main/universal/ProxyAdmin.sol";

import {Proxy} from "@main/universal/Proxy.sol";

import { SuperchainConfig } from "@main/L1/SuperchainConfig.sol";
import { ProtocolVersions } from "@main/L1/ProtocolVersions.sol";


string constant Artifact_SafeProxyFactory = "SafeProxyFactory.sol:SafeProxyFactory";
string constant Artifact_Safe = "Safe.sol:Safe";

string constant Artifact_AddressManager = "AddressManager.sol:AddressManager";
string constant Artifact_ProxyAdmin = "ProxyAdmin.sol:ProxyAdmin";
string constant Artifact_Proxy = "Proxy.sol:Proxy";

string constant Artifact_SuperchainConfig = "SuperchainConfig.sol:SuperchainConfig";
string constant Artifact_ProtocolVersions = "ProtocolVersions.sol:ProtocolVersions";


library DeployerFunctions {
        /// @notice Foundry cheatcode VM.
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

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
        address owner,
        bytes32 implSalt
    ) internal returns (SafeProxy) {
        console.log("Deploying SystemOwnerSafe");
        bytes32 salt = keccak256(abi.encode(name, implSalt));


        SafeProxyFactory safeProxyFactory = SafeProxyFactory(deployer.mustGetAddress(safeProxyFactoryName));
        Safe safeSingleton = Safe(deployer.mustGetAddress(safeSingletonyName));

        address[] memory signers = new address[](1);
        signers[0] = owner;

        bytes memory initData = abi.encodeWithSelector(
            Safe.setup.selector, signers, 1, address(0), hex"", address(0), address(0), 0, address(0)
        );

        SafeProxy safeProxy = safeProxyFactory.createProxyWithNonce(address(safeSingleton), initData, uint256(salt));
        deployer.save(name, address(safeProxy));
        console.log("New SystemOwnerSafe deployed at %s", address(safeProxy));

        return safeProxy;
    }

    function deploy_AddressManager(IDeployer deployer, string memory name) internal returns (AddressManager) {
        console.log("Deploying AddressManager");
        bytes memory args = abi.encode();
        return AddressManager(DefaultDeployerFunction.deploy(deployer, name, Artifact_AddressManager, args));
    }

    function deploy_ProxyAdmin(IDeployer deployer, string memory name, address _owner) internal returns (ProxyAdmin) {
        console.log("Deploying ProxyAdmin");
        bytes memory args = abi.encode(_owner);
        return ProxyAdmin(DefaultDeployerFunction.deploy(deployer, name, Artifact_ProxyAdmin, args));
    }

    function deploy_ProxyAdmin(IDeployer deployer, string memory name, address _owner, DeployOptions memory options)
        internal
        returns (ProxyAdmin)
    {
        console.log("Deploying ProxyAdmin");
        bytes memory args = abi.encode(_owner);
        return ProxyAdmin(DefaultDeployerFunction.deploy(deployer, name, Artifact_ProxyAdmin, args, options));
    }

    /// @notice Deploys an ERC1967Proxy contract with a specified owner.
    function deploy_ERC1967Proxy(IDeployer deployer, string memory name, address _proxyOwner)
        internal
        returns (Proxy)
    {
        console.log("Deploying ERC1967Proxy");

        // Proxy proxy = new Proxy({ _admin: _proxyOwner });
        // deployer.save(name, address(proxy));

        bytes memory args = abi.encode(_proxyOwner);
        Proxy proxy = Proxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_Proxy, args));

        require(EIP1967Helper.getAdmin(address(proxy)) == _proxyOwner, "Admin address must equal the owner param");
        return proxy;
    }

    function deploy_ERC1967Proxy(IDeployer deployer, string memory name, address _proxyOwner, DeployOptions memory options)
        internal
        returns (Proxy)
    {
        console.log("Deploying ERC1967Proxy");

        // Proxy proxy = new Proxy({ _admin: _proxyOwner });
        // deployer.save(name, address(proxy));

        bytes memory args = abi.encode(_proxyOwner);
        Proxy proxy = Proxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_Proxy, args, options));

        require(EIP1967Helper.getAdmin(address(proxy)) == _proxyOwner, "admin must equal owner");
        return proxy;
    }

    function deploy_SuperchainConfig(IDeployer deployer, string memory name)
        internal
        returns (SuperchainConfig)
    {
        console.log("Deploying SuperchainConfig");
        bytes memory args = abi.encode();
        SuperchainConfig config = SuperchainConfig(DefaultDeployerFunction.deploy(deployer, name, Artifact_SuperchainConfig, args));

        require(config.guardian() == address(0), "Guardian must be still empty" );
        bytes32 initialized = vm.load(address(config), bytes32(0));
        require(initialized != 0, "Must be initialized" );
        return config;
    }

    function deploy_SuperchainConfig(IDeployer deployer, string memory name,  DeployOptions memory options)
        internal
        returns (SuperchainConfig)
    {
        console.log("Deploying SuperchainConfig");
        bytes memory args = abi.encode();
        SuperchainConfig config = SuperchainConfig(DefaultDeployerFunction.deploy(deployer, name, Artifact_SuperchainConfig, args, options));

        require(config.guardian() == address(0), "Guardian must be still empty" );
        bytes32 initialized = vm.load(address(config), bytes32(0));
        require(initialized != 0, "Must be initialized" );
        return config;
    }

    function deploy_ProtocolVersions(IDeployer deployer, string memory name)
        internal
        returns (ProtocolVersions)
    {
        console.log("Deploying ProtocolVersions");
        bytes memory args = abi.encode();
        return ProtocolVersions(DefaultDeployerFunction.deploy(deployer, name, Artifact_ProtocolVersions, args));
    }

    function deploy_ProtocolVersions(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (ProtocolVersions)
    {
        console.log("Deploying ProtocolVersions");
        bytes memory args = abi.encode();
        return ProtocolVersions(DefaultDeployerFunction.deploy(deployer, name, Artifact_ProtocolVersions, args, options));
    }

}
