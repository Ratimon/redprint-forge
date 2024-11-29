// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from "@redprint-forge-std/console2.sol";
import { Vm } from "@redprint-forge-std/Vm.sol";

import {IDeployer} from "@redprint-deploy/deployer/Deployer.sol";
import {DefaultDeployerFunction, DeployOptions} from "@redprint-deploy/deployer/DefaultDeployerFunction.sol";

import {IPreimageOracle} from "@redprint-core/cannon/interfaces/IPreimageOracle.sol";
import {IDisputeGameFactory} from "@redprint-core/dispute/interfaces/IDisputeGameFactory.sol";

import { EIP1967Helper } from "@redprint-core/universal/EIP1967Helper.sol";

import {SafeProxy} from "@redprint-safe-contracts/proxies/SafeProxy.sol";
import {SafeProxyFactory} from "@redprint-safe-contracts/proxies/SafeProxyFactory.sol";
import {Safe} from "@redprint-safe-contracts/Safe.sol";

import {AddressManager} from "@redprint-core/legacy/AddressManager.sol";
import {ProxyAdmin} from "@redprint-core/universal/ProxyAdmin.sol";

import {Proxy} from "@redprint-core/universal/Proxy.sol";
import {ResolvedDelegateProxy} from "@redprint-core/legacy/ResolvedDelegateProxy.sol";
import {L1ChugSplashProxy} from "@redprint-core/legacy/L1ChugSplashProxy.sol";

import { SuperchainConfig } from "@redprint-core/L1/SuperchainConfig.sol";
import { ProtocolVersions } from "@redprint-core/L1/ProtocolVersions.sol";

import {L1CrossDomainMessenger} from "@redprint-core/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@redprint-core/universal/OptimismMintableERC20Factory.sol";
import {SystemConfig} from "@redprint-core/L1/SystemConfig.sol";
import {SystemConfigInterop} from "@redprint-core/L1/SystemConfigInterop.sol";
import {L1StandardBridge} from "@redprint-core/L1/L1StandardBridge.sol";
import {L1ERC721Bridge} from "@redprint-core/L1/L1ERC721Bridge.sol";
import {OptimismPortal} from "@redprint-core/L1/OptimismPortal.sol";
import {L2OutputOracle} from "@redprint-core/L1/L2OutputOracle.sol";
import {OptimismPortal2} from "@redprint-core/L1/OptimismPortal2.sol";
import {OptimismPortalInterop} from "@redprint-core/L1/OptimismPortalInterop.sol";
import {DisputeGameFactory} from "@redprint-core/dispute/DisputeGameFactory.sol";
import {DelayedWETH} from "@redprint-core/dispute/DelayedWETH.sol";
import {PreimageOracle} from "@redprint-core/cannon/PreimageOracle.sol";
import {MIPS} from "@redprint-core/cannon/MIPS.sol";
import {AnchorStateRegistry} from "@redprint-core/dispute/AnchorStateRegistry.sol";



string constant Artifact_SafeProxyFactory = "SafeProxyFactory.sol:SafeProxyFactory";
string constant Artifact_Safe = "Safe.sol:Safe";

string constant Artifact_AddressManager = "AddressManager.sol:AddressManager";
string constant Artifact_ProxyAdmin = "ProxyAdmin.sol:ProxyAdmin";
string constant Artifact_Proxy = "Proxy.sol:Proxy";
string constant Artifact_ResolvedDelegateProxy = "ResolvedDelegateProxy.sol:ResolvedDelegateProxy";
string constant Artifact_L1ChugSplashProxy = "L1ChugSplashProxy.sol:L1ChugSplashProxy";

string constant Artifact_SuperchainConfig = "SuperchainConfig.sol:SuperchainConfig";
string constant Artifact_ProtocolVersions = "ProtocolVersions.sol:ProtocolVersions";

string constant Artifact_L1CrossDomainMessenger = "L1CrossDomainMessenger.sol:L1CrossDomainMessenger";
string constant Artifact_OptimismMintableERC20Factory = "OptimismMintableERC20Factory.sol:OptimismMintableERC20Factory";
string constant Artifact_SystemConfig = "SystemConfig.sol:SystemConfig";
string constant Artifact_SystemConfigInterop = "SystemConfigInterop.sol:SystemConfigInterop";
string constant Artifact_L1StandardBridge = "L1StandardBridge.sol:L1StandardBridge";
string constant Artifact_L1ERC721Bridge = "L1ERC721Bridge.sol:L1ERC721Bridge";
string constant Artifact_OptimismPortal = "OptimismPortal.sol:OptimismPortal";
string constant Artifact_L2OutputOracle = "L2OutputOracle.sol:L2OutputOracle";
string constant Artifact_OptimismPortal2 = "OptimismPortal2.sol:OptimismPortal2";
string constant Artifact_OptimismPortalInterop = "OptimismPortalInterop.sol:OptimismPortalInterop";
string constant Artifact_DisputeGameFactory = "DisputeGameFactory.sol:DisputeGameFactory";
string constant Artifact_DelayedWETH = "DelayedWETH.sol:DelayedWETH";
string constant Artifact_PreimageOracle = "PreimageOracle.sol:PreimageOracle";
string constant Artifact_MIPS = "MIPS.sol:MIPS";
string constant Artifact_AnchorStateRegistry = "AnchorStateRegistry.sol:AnchorStateRegistry";



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

        bytes memory args = abi.encode(_proxyOwner);
        Proxy proxy = Proxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1ChugSplashProxy, args, options));

        require(EIP1967Helper.getAdmin(address(proxy)) == _proxyOwner, "admin must equal owner");
        return proxy;
    }



    function deploy_L1ChugSplashProxy(IDeployer deployer, string memory name, address _proxyOwner)
        internal
        returns (L1ChugSplashProxy)
    {
        console.log("Deploying L1ChugSplashProxy");

        bytes memory args = abi.encode(_proxyOwner);
        L1ChugSplashProxy proxy = L1ChugSplashProxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1ChugSplashProxy, args));

        require(EIP1967Helper.getAdmin(address(proxy)) == _proxyOwner, "Admin address must equal the owner param");
        return proxy;
    }

    function deploy_L1ChugSplashProxy(IDeployer deployer, string memory name, address _proxyOwner, DeployOptions memory options)
        internal
        returns (L1ChugSplashProxy)
    {
        console.log("Deploying L1ChugSplashProxy");

        bytes memory args = abi.encode(_proxyOwner);
        L1ChugSplashProxy proxy = L1ChugSplashProxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_Proxy, args, options));

        require(EIP1967Helper.getAdmin(address(proxy)) == _proxyOwner, "Admin address must equal the owner param");
        return proxy;
    }

    function deploy_ResolvedDelegateProxy(IDeployer deployer, string memory name, address _addressManager, string memory _implementationName)
        internal
        returns (ResolvedDelegateProxy)
    {
        console.log("Deploying ResolvedDelegateProxy");

        bytes memory args = abi.encode(_addressManager, _implementationName);
        ResolvedDelegateProxy proxy = ResolvedDelegateProxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_ResolvedDelegateProxy, args));
        return proxy;
    }

    function deploy_ResolvedDelegateProxy(IDeployer deployer,string memory name, address _addressManager, string memory _implementationName,  DeployOptions memory options)
        internal
        returns (ResolvedDelegateProxy)
    {
        console.log("Deploying ResolvedDelegateProxy");

        bytes memory args = abi.encode(_addressManager, _implementationName);
        ResolvedDelegateProxy proxy = ResolvedDelegateProxy(DefaultDeployerFunction.deploy(deployer, name, Artifact_ResolvedDelegateProxy, args, options));
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

    function deploy_L1CrossDomainMessenger(IDeployer deployer, string memory name)
        internal
        returns (L1CrossDomainMessenger)
    {
        console.log("Deploying L1CrossDomainMessenger");
        bytes memory args = abi.encode();
        return L1CrossDomainMessenger(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1CrossDomainMessenger, args));
    }

    function deploy_L1CrossDomainMessenger(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (L1CrossDomainMessenger)
    {
        console.log("Deploying L1CrossDomainMessenger");
        bytes memory args = abi.encode();
        return L1CrossDomainMessenger(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1CrossDomainMessenger, args, options));
    }

    function deploy_OptimismMintableERC20Factory(IDeployer deployer, string memory name)
        internal
        returns (OptimismMintableERC20Factory)
    {
        console.log("Deploying OptimismMintableERC20Factory");
        bytes memory args = abi.encode();
        return OptimismMintableERC20Factory(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismMintableERC20Factory, args));
    }

    function deploy_OptimismMintableERC20Factory(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (OptimismMintableERC20Factory)
    {
        console.log("Deploying OptimismMintableERC20Factory");
        bytes memory args = abi.encode();
        return OptimismMintableERC20Factory(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismMintableERC20Factory, args, options));
    }

    function deploy_SystemConfig(IDeployer deployer, string memory name)
        internal
        returns (SystemConfig)
    {
        console.log("Deploying SystemConfig");
        bytes memory args = abi.encode();
        return SystemConfig(DefaultDeployerFunction.deploy(deployer, name, Artifact_SystemConfig, args));
    }

    function deploy_SystemConfig(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (SystemConfig)
    {
        console.log("Deploying SystemConfig");
        bytes memory args = abi.encode();
        return SystemConfig(DefaultDeployerFunction.deploy(deployer, name, Artifact_SystemConfig, args, options));
    }

    function deploy_SystemConfigInterop(IDeployer deployer, string memory name)
        internal
        returns (SystemConfigInterop)
    {
        console.log("Deploying SystemConfigInterop");
        bytes memory args = abi.encode();
        return SystemConfigInterop(DefaultDeployerFunction.deploy(deployer, name, Artifact_SystemConfigInterop, args));
    }

    function deploy_SystemConfigInterop(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (SystemConfigInterop)
    {
        console.log("Deploying SystemConfigInterop");
        bytes memory args = abi.encode();
        return SystemConfigInterop(DefaultDeployerFunction.deploy(deployer, name, Artifact_SystemConfigInterop, args, options));
    }

    function deploy_L1StandardBridge(IDeployer deployer, string memory name)
        internal
        returns (L1StandardBridge)
    {
        console.log("Deploying L1StandardBridge");
        bytes memory args = abi.encode();
        return L1StandardBridge(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1StandardBridge, args));
    }

    function deploy_L1StandardBridge(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (L1StandardBridge)
    {
        console.log("Deploying L1StandardBridge");
        bytes memory args = abi.encode();
        return L1StandardBridge(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1StandardBridge, args, options));
    }

    function deploy_L1ERC721Bridge(IDeployer deployer, string memory name)
        internal
        returns (L1ERC721Bridge)
    {
        console.log("Deploying L1ERC721Bridge");
        bytes memory args = abi.encode();
        return L1ERC721Bridge(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1ERC721Bridge, args));
    }

    function deploy_L1ERC721Bridge(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (L1ERC721Bridge)
    {
        console.log("Deploying L1ERC721Bridge");
        bytes memory args = abi.encode();
        return L1ERC721Bridge(DefaultDeployerFunction.deploy(deployer, name, Artifact_L1ERC721Bridge, args, options));
    }

    function deploy_OptimismPortal(IDeployer deployer, string memory name)
        internal
        returns (OptimismPortal)
    {
        console.log("Deploying OptimismPortal");
        bytes memory args = abi.encode();
        return OptimismPortal(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismPortal, args));
    }

    function deploy_OptimismPortal(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (OptimismPortal)
    {
        console.log("Deploying OptimismPortal");
        bytes memory args = abi.encode();
        return OptimismPortal(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismPortal, args, options));
    }

    function deploy_L2OutputOracle(IDeployer deployer, string memory name)
        internal
        returns (L2OutputOracle)
    {
        console.log("Deploying L2OutputOracle");
        bytes memory args = abi.encode();
        return L2OutputOracle(DefaultDeployerFunction.deploy(deployer, name, Artifact_L2OutputOracle, args));
    }

    function deploy_L2OutputOracle(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (L2OutputOracle)
    {
        console.log("Deploying L2OutputOracle");
        bytes memory args = abi.encode();
        return L2OutputOracle(DefaultDeployerFunction.deploy(deployer, name, Artifact_L2OutputOracle, args, options));
    }

    function deploy_OptimismPortal2(IDeployer deployer, string memory name, uint256 _proofMaturityDelaySeconds, uint256 _disputeGameFinalityDelaySeconds)
        internal
        returns (OptimismPortal2)
    {
        console.log("Deploying OptimismPortal2");
        bytes memory args = abi.encode(_proofMaturityDelaySeconds, _disputeGameFinalityDelaySeconds);
        return OptimismPortal2(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismPortal2, args));
    }

    function deploy_OptimismPortal2(IDeployer deployer, string memory name, uint256 _proofMaturityDelaySeconds, uint256 _disputeGameFinalityDelaySeconds, DeployOptions memory options)
        internal
        returns (OptimismPortal2)
    {
        console.log("Deploying OptimismPortal2");
        bytes memory args = abi.encode(_proofMaturityDelaySeconds, _disputeGameFinalityDelaySeconds);
        return OptimismPortal2(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismPortal2, args, options));
    }

    function deploy_OptimismPortalInterop(IDeployer deployer, string memory name,uint256 _proofMaturityDelaySeconds, uint256 _disputeGameFinalityDelaySeconds)
        internal
        returns (OptimismPortalInterop)
    {
        console.log("Deploying OptimismPortalInterop");
        bytes memory args = abi.encode(_proofMaturityDelaySeconds, _disputeGameFinalityDelaySeconds);
        return OptimismPortalInterop(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismPortalInterop, args));
    }

    function deploy_OptimismPortalInterop(IDeployer deployer, string memory name,uint256 _proofMaturityDelaySeconds, uint256 _disputeGameFinalityDelaySeconds, DeployOptions memory options)
        internal
        returns (OptimismPortalInterop)
    {
        console.log("Deploying OptimismPortalInterop");
        bytes memory args = abi.encode(_proofMaturityDelaySeconds, _disputeGameFinalityDelaySeconds);
        return OptimismPortalInterop(DefaultDeployerFunction.deploy(deployer, name, Artifact_OptimismPortalInterop, args, options));
    }

    function deploy_DisputeGameFactory(IDeployer deployer, string memory name)
        internal
        returns (DisputeGameFactory)
    {
        console.log("Deploying DisputeGameFactory");
        bytes memory args = abi.encode();
        return DisputeGameFactory(DefaultDeployerFunction.deploy(deployer, name, Artifact_DisputeGameFactory, args));
    }

    function deploy_DisputeGameFactory(IDeployer deployer, string memory name, DeployOptions memory options)
        internal
        returns (DisputeGameFactory)
    {
        console.log("Deploying DisputeGameFactory");
        bytes memory args = abi.encode();
        return DisputeGameFactory(DefaultDeployerFunction.deploy(deployer, name, Artifact_DisputeGameFactory, args, options));
    }

    function deploy_DelayedWETH(IDeployer deployer, string memory name , uint256 _faultGameWithdrawalDelay)
        internal
        returns (DelayedWETH)
    {
        console.log("Deploying DelayedWETH");
        bytes memory args = abi.encode(_faultGameWithdrawalDelay);
        return DelayedWETH(DefaultDeployerFunction.deploy(deployer, name, Artifact_DelayedWETH, args));
    }

    function deploy_DelayedWETH(IDeployer deployer, string memory name , uint256 _faultGameWithdrawalDelay, DeployOptions memory options)
        internal
        returns (DelayedWETH)
    {
        console.log("Deploying DelayedWETH");
        bytes memory args = abi.encode(_faultGameWithdrawalDelay);
        return DelayedWETH(DefaultDeployerFunction.deploy(deployer, name, Artifact_DelayedWETH, args, options));
    }

    function deploy_PreimageOracle(IDeployer deployer, string memory name, uint256 _minProposalSize, uint256 _challengePeriod)
        internal
        returns (PreimageOracle)
    {
        console.log("Deploying PreimageOracle");
        bytes memory args = abi.encode(_minProposalSize, _challengePeriod);
        return PreimageOracle(DefaultDeployerFunction.deploy(deployer, name, Artifact_PreimageOracle, args));
    }

    function deploy_PreimageOracle(IDeployer deployer, string memory name, uint256 _minProposalSize, uint256 _challengePeriod, DeployOptions memory options)
        internal
        returns (PreimageOracle)
    {
        console.log("Deploying PreimageOracle");
        bytes memory args = abi.encode(_minProposalSize, _challengePeriod);
        return PreimageOracle(DefaultDeployerFunction.deploy(deployer, name, Artifact_PreimageOracle, args, options));
    }

    function deploy_MIPS(IDeployer deployer, string memory name, IPreimageOracle _preimageOracle)
        internal
        returns (MIPS)
    {
        console.log("Deploying MIPS");
        bytes memory args = abi.encode(_preimageOracle);
        return MIPS(DefaultDeployerFunction.deploy(deployer, name, Artifact_MIPS, args));
    }

    function deploy_MIPS(IDeployer deployer, string memory name, IPreimageOracle _preimageOracle, DeployOptions memory options)
        internal
        returns (MIPS)
    {
        console.log("Deploying MIPS");
        bytes memory args = abi.encode(_preimageOracle);
        return MIPS(DefaultDeployerFunction.deploy(deployer, name, Artifact_MIPS, args, options));
    }

    function deploy_AnchorStateRegistry(IDeployer deployer, string memory name, IDisputeGameFactory _disputeGameFactory)
        internal
        returns (AnchorStateRegistry)
    {
        console.log("Deploying AnchorStateRegistry");
        bytes memory args = abi.encode(_disputeGameFactory);
        return AnchorStateRegistry(DefaultDeployerFunction.deploy(deployer, name, Artifact_AnchorStateRegistry, args));
    }

    function deploy_AnchorStateRegistry(IDeployer deployer, string memory name, IDisputeGameFactory _disputeGameFactory, DeployOptions memory options)
        internal
        returns (AnchorStateRegistry)
    {
        console.log("Deploying AnchorStateRegistry");
        bytes memory args = abi.encode(_disputeGameFactory);
        return AnchorStateRegistry(DefaultDeployerFunction.deploy(deployer, name, Artifact_AnchorStateRegistry, args, options));
    }

}
