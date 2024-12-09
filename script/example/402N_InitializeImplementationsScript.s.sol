// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "@redprint-forge-std/Script.sol";
import {SafeScript} from "@redprint-deploy/safe-management/SafeScript.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";
import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";
import {Constants} from "@redprint-core/libraries/Constants.sol";
import {IL2OutputOracle} from "@redprint-core/L1/interfaces/IL2OutputOracle.sol";
import {ISystemConfig} from "@redprint-core/L1/interfaces/ISystemConfig.sol";
import {ISuperchainConfig} from "@redprint-core/L1/interfaces/ISuperchainConfig.sol";
import {OptimismPortal} from "@redprint-core/L1/OptimismPortal.sol";
import {SystemConfig} from "@redprint-core/L1/SystemConfig.sol";
import {IL1CrossDomainMessenger} from "@redprint-core/L1/interfaces/IL1CrossDomainMessenger.sol";
import {ProxyAdmin} from "@redprint-core/universal/ProxyAdmin.sol";
import {Safe} from "@redprint-safe-contracts/Safe.sol";
import {L1StandardBridge} from "@redprint-core/L1/L1StandardBridge.sol";
import {L1ERC721Bridge} from "@redprint-core/L1/L1ERC721Bridge.sol";
import {OptimismMintableERC20Factory} from "@redprint-core/universal/OptimismMintableERC20Factory.sol";
import {IOptimismPortal} from "@redprint-core/L1/interfaces/IOptimismPortal.sol";
import {L1CrossDomainMessenger} from "@redprint-core/L1/L1CrossDomainMessenger.sol";
import {L2OutputOracle} from "@redprint-core/L1/L2OutputOracle.sol";
import {DisputeGameFactory} from "@redprint-core/dispute/DisputeGameFactory.sol";

import {DelayedWETH} from "@redprint-core/dispute/DelayedWETH.sol";
// import {PermissionedDelayedWETH} from "@redprint-core/dispute/PermissionedDelayedWETH.sol";

import {AnchorStateRegistry} from "@redprint-core/dispute/AnchorStateRegistry.sol";
import { GameTypes, OutputRoot, Hash } from "@redprint-core/dispute/lib/Types.sol";


contract InitializeImplementationsScript is Script, SafeScript {
    IDeployer deployerProcedue;
    address public constant customGasTokenAddress = Constants.ETHER;
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
            initializeOptimismPortal();
            initializeSystemConfig();
            initializeL1StandardBridge();
            initializeL1ERC721Bridge();
            initializeOptimismMintableERC20Factory();
            initializeL1CrossDomainMessenger();
            initializeL2OutputOracle();
            initializeDisputeGameFactory();
            initializeDelayedWETH();
            initializePermissionedDelayedWETH();
            initializeAnchorStateRegistry();
            console.log("Pranking Stopped ...");

            vm.stopPrank();
        } else {
            console.log("Broadcasting ...");
            vm.startBroadcast(owner);
            initializeOptimismPortal();
            initializeSystemConfig();
            initializeL1StandardBridge();
            initializeL1ERC721Bridge();
            initializeOptimismMintableERC20Factory();
            initializeL1CrossDomainMessenger();
            initializeL2OutputOracle();
            initializeDisputeGameFactory();
            initializeDelayedWETH();
            initializePermissionedDelayedWETH();
            initializeAnchorStateRegistry();
            console.log("Broadcasted");

            vm.stopBroadcast();
        }
    }

    function initializeOptimismPortal() internal {
        console.log("Upgrading and initializing OptimismPortal2 proxy");

        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address optimismPortalProxy = deployerProcedue.mustGetAddress("OptimismPortalProxy");
        address optimismPortal = deployerProcedue.mustGetAddress("OptimismPortal");
        address l2OutputOracleProxy = deployerProcedue.mustGetAddress("L2OutputOracleProxy");
        address systemConfigProxy = deployerProcedue.mustGetAddress("SystemConfigProxy");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");

        DeployConfig cfg = deployerProcedue.getConfig();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,   
            _proxy: payable(optimismPortalProxy),
            _implementation: optimismPortal,
            _innerCallData: abi.encodeCall(
                OptimismPortal.initialize,
                    (
                        IL2OutputOracle(l2OutputOracleProxy),
                        ISystemConfig(systemConfigProxy),
                        ISuperchainConfig(superchainConfigProxy)
                    )
            )
        });

        OptimismPortal portal = OptimismPortal(payable(optimismPortalProxy));
        string memory version = portal.version();
        console.log("OptimismPortal2 version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkOptimismPortal({ _contracts: proxies, _cfg: cfg, _isProxy: true });
    }

    function initializeSystemConfig() internal {
        console.log("Upgrading and initializing SystemConfig proxy");

        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address systemConfigProxy = deployerProcedue.mustGetAddress("SystemConfigProxy");
        address systemConfig = deployerProcedue.mustGetAddress("SystemConfig");

        DeployConfig cfg = deployerProcedue.getConfig();

        bytes32 batcherHash = bytes32(uint256(uint160(cfg.batchSenderAddress())));

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,   
            _proxy: payable(systemConfigProxy),
            _implementation: systemConfig,
            _innerCallData: abi.encodeCall(
                SystemConfig.initialize,
                (
                    cfg.finalSystemOwner(),
                    cfg.basefeeScalar(),
                    cfg.blobbasefeeScalar(),
                    batcherHash,
                    uint64(cfg.l2GenesisBlockGasLimit()),
                    cfg.p2pSequencerAddress(),
                    Constants.DEFAULT_RESOURCE_CONFIG(),
                    cfg.batchInboxAddress(),
                    SystemConfig.Addresses({
                        l1CrossDomainMessenger: deployerProcedue.mustGetAddress("L1CrossDomainMessengerProxy"),
                        l1ERC721Bridge: deployerProcedue.mustGetAddress("L1ERC721BridgeProxy"),
                        l1StandardBridge: deployerProcedue.mustGetAddress("L1StandardBridgeProxy"),
                        disputeGameFactory: deployerProcedue.mustGetAddress("DisputeGameFactoryProxy"),
                        optimismPortal: deployerProcedue.mustGetAddress("OptimismPortalProxy"),
                        optimismMintableERC20Factory: deployerProcedue.mustGetAddress("OptimismMintableERC20FactoryProxy"),
                        gasPayingToken: customGasTokenAddress 
                    })
                )
            )
        });

        SystemConfig config = SystemConfig(systemConfigProxy);
        string memory version = config.version();
        console.log("SystemConfig version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkSystemConfig({ _contracts: proxies, _cfg: cfg, _isProxy: true });
    }

    function initializeL1StandardBridge() internal {
        console.log("Upgrading and initializing L1StandardBridge proxy");
        address proxyAdminAddress = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safeAddress = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address l1StandardBridgeProxy = deployerProcedue.mustGetAddress("L1StandardBridgeProxy");
        address l1StandardBridge = deployerProcedue.mustGetAddress("L1StandardBridge");
        address l1CrossDomainMessengerProxy = deployerProcedue.mustGetAddress("L1CrossDomainMessengerProxy");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");
        address systemConfigProxy = deployerProcedue.mustGetAddress("SystemConfigProxy");

        uint256 proxyType = uint256(ProxyAdmin(proxyAdminAddress).proxyType(l1StandardBridgeProxy));

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        Safe safe = Safe(payable(safeAddress));

        if (proxyType != uint256(ProxyAdmin.ProxyType.CHUGSPLASH)) {
            _callViaSafe({
                _safe: safe,
                _owner: owner,
                _target: address(proxyAdmin),
                _data: abi.encodeCall(ProxyAdmin.setProxyType, (l1StandardBridgeProxy, ProxyAdmin.ProxyType.CHUGSPLASH))
            });
        }

        require(uint256(proxyAdmin.proxyType(l1StandardBridgeProxy)) == uint256(ProxyAdmin.ProxyType.CHUGSPLASH),"Type not CHUGSPLASH");

        _upgradeAndCallViaSafe({
            _proxyAdmin: address(proxyAdmin),
            _safe: address(safe),
            _owner: owner,
            _proxy: payable(l1StandardBridgeProxy),
            _implementation: l1StandardBridge,
            _innerCallData: abi.encodeCall(
                L1StandardBridge.initialize,
                (
                    IL1CrossDomainMessenger(l1CrossDomainMessengerProxy),
                    ISuperchainConfig(superchainConfigProxy),
                    ISystemConfig(systemConfigProxy)
                )
            )
        });

        string memory version = L1StandardBridge(payable(l1StandardBridgeProxy)).version();
        console.log("L1StandardBridge version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkL1StandardBridge({ _contracts: proxies, _isProxy: true });
    }

    function initializeL1ERC721Bridge() internal {
        console.log("Upgrading and initializing L1ERC721Bridge proxy");
        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address l1ERC721BridgeProxy = deployerProcedue.mustGetAddress("L1ERC721BridgeProxy");
        address l1ERC721Bridge = deployerProcedue.mustGetAddress("L1ERC721Bridge");
        address l1CrossDomainMessengerProxy = deployerProcedue.mustGetAddress("L1CrossDomainMessengerProxy");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");
        address systemConfigProxy = deployerProcedue.mustGetAddress("SystemConfigProxy");

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(l1ERC721BridgeProxy),
            _implementation: l1ERC721Bridge,
            _innerCallData: abi.encodeCall(
                L1ERC721Bridge.initialize,
                (
                    IL1CrossDomainMessenger(l1CrossDomainMessengerProxy),
                    ISuperchainConfig(superchainConfigProxy)
                )
            )
        });

        L1ERC721Bridge bridge = L1ERC721Bridge(l1ERC721BridgeProxy);
        string memory version = bridge.version();
        console.log("L1ERC721Bridge version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();

        ChainAssertions.checkL1ERC721Bridge({ _contracts: proxies, _isProxy: true });
    }

    function initializeOptimismMintableERC20Factory() internal {
        console.log("Upgrading and initializing OptimismMintableERC20Factory proxy");
        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address optimismMintableERC20FactoryProxy = deployerProcedue.mustGetAddress("OptimismMintableERC20FactoryProxy");
        address optimismMintableERC20Factory = deployerProcedue.mustGetAddress("OptimismMintableERC20Factory");
        address l1StandardBridgeProxy = deployerProcedue.mustGetAddress("L1StandardBridgeProxy");

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(optimismMintableERC20FactoryProxy),
            _implementation: optimismMintableERC20Factory,
            _innerCallData: abi.encodeCall(OptimismMintableERC20Factory.initialize, (l1StandardBridgeProxy))
        });

        OptimismMintableERC20Factory factory = OptimismMintableERC20Factory(optimismMintableERC20FactoryProxy);
        string memory version = factory.version();
        console.log("OptimismMintableERC20Factory version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkOptimismMintableERC20Factory({ _contracts: proxies, _isProxy: true });
    }

    function initializeL1CrossDomainMessenger() internal {
        console.log("Upgrading and initializing L1CrossDomainMessenger Proxy");
        address proxyAdminAddress = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safeAddress = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address l1CrossDomainMessengerProxy = deployerProcedue.mustGetAddress("L1CrossDomainMessengerProxy");
        address l1CrossDomainMessenger = deployerProcedue.mustGetAddress("L1CrossDomainMessenger");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");
        address optimismPortalProxy = deployerProcedue.mustGetAddress("OptimismPortalProxy");
        address systemConfigProxy = deployerProcedue.mustGetAddress("SystemConfigProxy");

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        Safe safe = Safe(payable(safeAddress));

        uint256 proxyType = uint256(proxyAdmin.proxyType(l1CrossDomainMessengerProxy));
        
        if (proxyType != uint256(ProxyAdmin.ProxyType.RESOLVED)) {
            _callViaSafe({
                _safe: safe,
                _owner: owner,
                _target: address(proxyAdmin),
                _data: abi.encodeCall(
                    ProxyAdmin.setProxyType,
                    (
                        l1CrossDomainMessengerProxy,
                        ProxyAdmin.ProxyType.RESOLVED
                    )
                )
            });
        }
        require(uint256(proxyAdmin.proxyType(l1CrossDomainMessengerProxy)) == uint256(ProxyAdmin.ProxyType.RESOLVED));

        string memory contractName = "OVM_L1CrossDomainMessenger";
        string memory implName = proxyAdmin.implementationName(l1CrossDomainMessenger);
        if (keccak256(bytes(contractName)) != keccak256(bytes(implName))) {
            _callViaSafe({
                _safe: safe,
                _owner: owner,
                _target: address(proxyAdmin),
                _data: abi.encodeCall(
                    ProxyAdmin.setImplementationName,
                    (
                        l1CrossDomainMessengerProxy,
                        contractName
                    )
                )
            });
        }
        require(
            keccak256(bytes(proxyAdmin.implementationName(l1CrossDomainMessengerProxy)))
                == keccak256(bytes(contractName))
        );

        _upgradeAndCallViaSafe({
            _proxyAdmin: address(proxyAdmin),
            _safe: address(safe),
            _owner: owner,
            _proxy: payable(l1CrossDomainMessengerProxy),
            _implementation: l1CrossDomainMessenger,
            _innerCallData: abi.encodeCall(
                L1CrossDomainMessenger.initialize,
                (
                    ISuperchainConfig(superchainConfigProxy),
                    IOptimismPortal(payable(optimismPortalProxy)),
                    ISystemConfig(systemConfigProxy)
                )
            )
        });

        L1CrossDomainMessenger messenger = L1CrossDomainMessenger(l1CrossDomainMessengerProxy);
        string memory version = messenger.version();
        console.log("L1CrossDomainMessenger version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkL1CrossDomainMessenger({ _contracts: proxies, _vm: vm, _isProxy: true });
    }

    function initializeL2OutputOracle() internal {
        console.log("Upgrading and initializing L2OutputOracle proxy");
        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address l2OutputOracleProxy = deployerProcedue.mustGetAddress("L2OutputOracleProxy");
        address l2OutputOracle = deployerProcedue.mustGetAddress("L2OutputOracle");

        DeployConfig cfg = deployerProcedue.getConfig();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: address(safe),
            _owner: owner,
            _proxy: payable(l2OutputOracleProxy),
            _implementation: l2OutputOracle,
            _innerCallData: abi.encodeCall(
                L2OutputOracle.initialize,
                (
                    cfg.l2OutputOracleSubmissionInterval(),
                    cfg.l2BlockTime(),
                    cfg.l2OutputOracleStartingBlockNumber(),
                    cfg.l2OutputOracleStartingTimestamp(),
                    cfg.l2OutputOracleProposer(),
                    cfg.l2OutputOracleChallenger(),
                    cfg.finalizationPeriodSeconds()
                )
            )
        });

        L2OutputOracle oracle = L2OutputOracle(l2OutputOracleProxy);
        string memory version = oracle.version();
        console.log("L2OutputOracle version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();

        ChainAssertions.checkL2OutputOracle({
            _contracts: proxies,
            _cfg: cfg,
            _l2OutputOracleStartingTimestamp: cfg.l2OutputOracleStartingTimestamp(),
            _isProxy: true
        });
    }

    function initializeDisputeGameFactory() internal {
        console.log("Upgrading and initializing DisputeGameFactory proxy");
        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address disputeGameFactoryProxy = deployerProcedue.mustGetAddress("DisputeGameFactoryProxy");
        address disputeGameFactory = deployerProcedue.mustGetAddress("DisputeGameFactory");

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(disputeGameFactoryProxy),
            _implementation: disputeGameFactory,
            _innerCallData: abi.encodeCall(
                DisputeGameFactory.initialize,
                (owner)
            )
        });

        string memory version = DisputeGameFactory(disputeGameFactoryProxy).version();
        console.log("DisputeGameFactory version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkDisputeGameFactory({ _contracts: proxies, _expectedOwner: owner, _isProxy: true });
    }

    function initializeDelayedWETH() internal {
        console.log("Upgrading and initializing DelayedWETH proxy");
        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address delayedWETHProxy = deployerProcedue.mustGetAddress("DelayedWETHProxy");
        address delayedWETH = deployerProcedue.mustGetAddress("DelayedWETH");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");

        DeployConfig cfg = deployerProcedue.getConfig();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(delayedWETHProxy),
            _implementation: delayedWETH,
            _innerCallData: abi.encodeCall(
                DelayedWETH.initialize, (
                    owner,
                    ISuperchainConfig(superchainConfigProxy)
                )
            )
        });

        string memory version = DelayedWETH(payable(delayedWETHProxy)).version();
        console.log("DelayedWETH version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkDelayedWETH({
            _contracts: proxies,
            _cfg: cfg,
            _isProxy: true,
            _expectedOwner: owner
        });
    }

    function initializePermissionedDelayedWETH() internal {
        console.log("Upgrading and initializing permissioned DelayedWETH proxy");

        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address delayedWETHProxy = deployerProcedue.mustGetAddress("PermissionedDelayedWETHProxy");
        address delayedWETH = deployerProcedue.mustGetAddress("DelayedWETH");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");

        DeployConfig cfg = deployerProcedue.getConfig();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(delayedWETHProxy),
            _implementation: delayedWETH,
            _innerCallData: abi.encodeCall(
                DelayedWETH.initialize, (
                    owner,
                    ISuperchainConfig(superchainConfigProxy)
                )
            )
        });

        string memory version = DelayedWETH(payable(delayedWETHProxy)).version();
        console.log("DelayedWETH version: %s", version);

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();

        ChainAssertions.checkPermissionedDelayedWETH({
            _contracts: proxies,
            _cfg: cfg,
            _isProxy: true,
            _expectedOwner: owner
        });
    }

    function initializeAnchorStateRegistry() internal {
        console.log("Upgrading and initializing AnchorStateRegistry proxy");

        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        address safe = deployerProcedue.mustGetAddress("SystemOwnerSafe");

        address anchorStateRegistryProxy = deployerProcedue.mustGetAddress("AnchorStateRegistryProxy");
        address anchorStateRegistry = deployerProcedue.mustGetAddress("AnchorStateRegistry");
        address superchainConfigProxy = deployerProcedue.mustGetAddress("SuperchainConfigProxy");

        DeployConfig cfg = deployerProcedue.getConfig();

        AnchorStateRegistry.StartingAnchorRoot[] memory roots = new AnchorStateRegistry.StartingAnchorRoot[](5);
        roots[0] = AnchorStateRegistry.StartingAnchorRoot({
            gameType: GameTypes.CANNON,
            outputRoot: OutputRoot({
                root: Hash.wrap(cfg.faultGameGenesisOutputRoot()),
                l2BlockNumber: cfg.faultGameGenesisBlock()
            })
        });
        roots[1] = AnchorStateRegistry.StartingAnchorRoot({
            gameType: GameTypes.PERMISSIONED_CANNON,
            outputRoot: OutputRoot({
                root: Hash.wrap(cfg.faultGameGenesisOutputRoot()),
                l2BlockNumber: cfg.faultGameGenesisBlock()
            })
        });
        roots[2] = AnchorStateRegistry.StartingAnchorRoot({
            gameType: GameTypes.ALPHABET,
            outputRoot: OutputRoot({
                root: Hash.wrap(cfg.faultGameGenesisOutputRoot()),
                l2BlockNumber: cfg.faultGameGenesisBlock()
            })
        });
        roots[3] = AnchorStateRegistry.StartingAnchorRoot({
            gameType: GameTypes.ASTERISC,
            outputRoot: OutputRoot({
                root: Hash.wrap(cfg.faultGameGenesisOutputRoot()),
                l2BlockNumber: cfg.faultGameGenesisBlock()
            })
        });
        roots[4] = AnchorStateRegistry.StartingAnchorRoot({
            gameType: GameTypes.FAST,
            outputRoot: OutputRoot({
                root: Hash.wrap(cfg.faultGameGenesisOutputRoot()),
                l2BlockNumber: cfg.faultGameGenesisBlock()
            })
        });

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(anchorStateRegistryProxy),
            _implementation: anchorStateRegistry,
            _innerCallData: abi.encodeCall(AnchorStateRegistry.initialize, (roots, ISuperchainConfig(superchainConfigProxy)))
        });

        string memory version = AnchorStateRegistry(payable(anchorStateRegistryProxy)).version();
        console.log("AnchorStateRegistry version: %s", version);
    }
}