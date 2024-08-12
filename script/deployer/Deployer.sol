// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "@redprint-forge-std/Vm.sol";
import {console2 as console} from "@redprint-forge-std/console2.sol";
import {stdJson} from "@redprint-forge-std/StdJson.sol";

import {Predeploys} from "@redprint-core/libraries/Predeploys.sol";
import {Config} from "@redprint-deploy/deployer/Config.sol";
import {ForgeArtifacts} from "@redprint-deploy/deployer/ForgeArtifacts.sol";

import { DeployConfig } from "@redprint-deploy/deployer/DeployConfig.s.sol";
import { Types } from "@redprint-deploy/optimism/Types.sol";


/// @notice represent a deployment
struct Deployment {
    string name;
    address payable addr;
}

struct Prank {
    bool active;
    address addr;
}

interface IDeployer {

    function getConfig() external pure returns (DeployConfig);

    function getProxiesUnstrict() external view returns (Types.ContractSet memory);


    /// @notice function that return whether deployments will be broadcasted
    function autoBroadcasting() external returns (bool);

    /// @notice function to activate/deactivate auto-broadcast, enabled by default
    ///  When activated, the deployment will be broadcasted automatically
    ///  Note that if prank is enabled, broadcast will be disabled
    /// @param broadcast whether to acitvate auto-broadcast
    function setAutoBroadcast(bool broadcast) external;

    function setAutoSave(bool enable) external;

    /// @notice function to activate prank for a given address
    /// @param addr address to prank
    function activatePrank(address addr) external;

    /// @notice function to deactivate prank if any is active
    function deactivatePrank() external;

    /// @notice function that return the prank status
    /// @return active whether prank is active
    /// @return addr the address that will be used to perform the deployment
    function prankStatus() external view returns (bool active, address addr);

    /// @notice function that return all new deployments as an array
    function newDeployments() external view returns (Deployment[] memory);

    /// @notice function that tell you whether a deployment already exists with that name
    /// @param name deployment's name to query
    /// @return exists whether the deployment exists or not
    function has(string memory name) external view returns (bool exists);

    /// @notice function that return the address of a deployment
    /// @param name deployment's name to query
    /// @return addr the deployment's address or the zero address
    function getAddress(string memory name) external view returns (address payable addr);

    function mustGetAddress(string memory _name) external view returns (address payable);

    /// @notice allow to override an existing deployment by ignoring the current one.
    /// the deployment will only be overriden on disk once the broadast is performed and `forge-deploy` sync is invoked.
    /// @param name deployment's name to override
    function ignoreDeployment(string memory name) external;

    /// @notice function that return the deployment (address, bytecode and args bytes used)
    /// @param name deployment's name to query
    /// @return deployment the deployment (with address zero if not existent)
    function get(string memory name) external view returns (Deployment memory deployment);

    function save(string memory name, address deployed) external;
}

/// @notice contract that keep track of the deployment and save them as return value in the forge's broadcast
contract GlobalDeployer is IDeployer {
    // --------------------------------------------------------------------------------------------
    // Constants
    // --------------------------------------------------------------------------------------------
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    DeployConfig public constant cfg =
        DeployConfig(address(uint160(uint256(keccak256(abi.encode("optimism.deployconfig"))))));

    error DeploymentDoesNotExist(string);
    /// @notice Error for when trying to save an invalid deployment
    error InvalidDeployment(string);
    /// @notice The set of deployments that have been done during execution.

    // --------------------------------------------------------------------------------------------
    // Storage
    // --------------------------------------------------------------------------------------------

    // Deployments
    mapping(string => Deployment) internal _namedDeployments;
    Deployment[] internal _newDeployments;

    bool internal _autoBroadcast = true;
    bool internal _autoSave = false;
    Prank internal _prank;
    string internal deploymentOutfile;

    /// @notice init a deployer with the current context
    /// the context is by default the current chainId
    /// but if the DEPLOYMENT_CONTEXT env variable is set, the context take that value
    /// The context allow you to organise deployments in a set as well as make specific configurations
    function init() external {


        // to do : refactor to internal
        vm.etch(address(cfg), vm.getDeployedCode("DeployConfig.s.sol:DeployConfig"));
        vm.label(address(cfg), "DeployConfig");
        vm.allowCheatcodes(address(cfg));
        cfg.read(Config.deployConfigPath());


        // needed as we etch the deployed code and so the initialization in the declaration above is not taken in consideration
        _autoBroadcast = true;
        _autoSave = false;

        deploymentOutfile = Config.deploymentOutfile();
        console.log("Writing artifact to %s", deploymentOutfile);
        ForgeArtifacts.ensurePath(deploymentOutfile);

        uint256 chainId = Config.chainID();
        console.log("Connected to network with chainid %s", chainId);

        // Load addresses from a JSON file if the CONTRACT_ADDRESSES_PATH environment variable
        // is set. Great for loading addresses from `superchain-registry`.
        string memory addresses = Config.contractAddressesPath();

        // when we run first script, we DONOT load the addresses
        // it will be generate the entire new deployment schema which will used later
        if (_autoSave) {
            if (bytes(addresses).length > 0) {
                // console.log("_autoSave");
                // console.logBool(_autoSave);
                console.log("Loading addresses from %s", addresses);
                _loadAddresses(addresses);
            }

            // then we load when running another deploy script
            _autoSave = true;
        }
    }

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------

    function getConfig() external pure returns (DeployConfig) {
        return cfg;
    }

    function autoBroadcasting() external view returns (bool) {
        return _autoBroadcast;
    }

    function setAutoBroadcast(bool broadcast) external {
        _autoBroadcast = broadcast;
    }

    function setAutoSave(bool _save) external {
        _autoSave = _save;
    }

    function activatePrank(address addr) external {
        _prank.active = true;
        _prank.addr = addr;
    }

    function deactivatePrank() external {
        _prank.active = false;
        _prank.addr = address(0);
    }

    function prankStatus() external view returns (bool active, address addr) {
        active = _prank.active;
        addr = _prank.addr;
    }

    /// @notice Populates the addresses to be used in a script based on a JSON file.
    ///         The format of the JSON file is the same that it output by this script
    ///         as well as the JSON files that contain addresses in the `superchain-registry`
    ///         repo. The JSON key is the name of the contract and the value is an address.
    function _loadAddresses(string memory _path) internal {
        string[] memory commands = new string[](3);
        commands[0] = "bash";
        commands[1] = "-c";
        commands[2] = string.concat("jq -cr < ", _path);
        string memory json = string(vm.ffi(commands));
        string[] memory keys = vm.parseJsonKeys(json, "");
        for (uint256 i; i < keys.length; i++) {
            string memory key = keys[i];
            address addr = stdJson.readAddress(json, string.concat("$.", key));
            save(key, addr);
        }
    }

    /// @notice Returns all of the deployments done in the current context.
    function newDeployments() external view returns (Deployment[] memory) {
        return _newDeployments;
    }

    /// @notice Returns whether or not a particular deployment exists.
    /// @param _name The name of the deployment.
    /// @return Whether the deployment exists or not.
    function has(string memory _name) public view returns (bool) {
        Deployment memory existing = _namedDeployments[_name];
        return bytes(existing.name).length > 0;
    }

    function getAddress(string memory _name) public view returns (address payable) {
        Deployment memory existing = _namedDeployments[_name];
        if (existing.addr != address(0)) {
            if (bytes(existing.name).length == 0) {
                return payable(address(0));
            }
            return existing.addr;
        }
        return payable(address(0));
    }

    /// @notice Returns the proxy addresses, not reverting if any are unset.
    function getProxiesUnstrict() external view returns (Types.ContractSet memory proxies_) {
        proxies_ = Types.ContractSet({
            L1CrossDomainMessenger: getAddress("L1CrossDomainMessengerProxy"),
            L1StandardBridge: getAddress("L1StandardBridgeProxy"),
            L2OutputOracle: getAddress("L2OutputOracleProxy"),
            DisputeGameFactory: getAddress("DisputeGameFactoryProxy"),
            DelayedWETH: getAddress("DelayedWETHProxy"),
            AnchorStateRegistry: getAddress("AnchorStateRegistryProxy"),
            OptimismMintableERC20Factory: getAddress("OptimismMintableERC20FactoryProxy"),
            OptimismPortal: getAddress("OptimismPortalProxy"),
            OptimismPortal2: getAddress("OptimismPortalProxy"),
            SystemConfig: getAddress("SystemConfigProxy"),
            L1ERC721Bridge: getAddress("L1ERC721BridgeProxy"),
            ProtocolVersions: getAddress("ProtocolVersionsProxy"),
            SuperchainConfig: getAddress("SuperchainConfigProxy")
        });
    }

    function getL2Address(string memory _name) public pure returns (address payable) {
        bytes32 digest = keccak256(bytes(_name));
        if (digest == keccak256(bytes("L2CrossDomainMessenger"))) {
            return payable(Predeploys.L2_CROSS_DOMAIN_MESSENGER);
        } else if (digest == keccak256(bytes("L2ToL1MessagePasser"))) {
            return payable(Predeploys.L2_TO_L1_MESSAGE_PASSER);
        } else if (digest == keccak256(bytes("L2StandardBridge"))) {
            return payable(Predeploys.L2_STANDARD_BRIDGE);
        } else if (digest == keccak256(bytes("L2ERC721Bridge"))) {
            return payable(Predeploys.L2_ERC721_BRIDGE);
        } else if (digest == keccak256(bytes("SequencerFeeWallet"))) {
            return payable(Predeploys.SEQUENCER_FEE_WALLET);
        } else if (digest == keccak256(bytes("OptimismMintableERC20Factory"))) {
            return payable(Predeploys.OPTIMISM_MINTABLE_ERC20_FACTORY);
        } else if (digest == keccak256(bytes("OptimismMintableERC721Factory"))) {
            return payable(Predeploys.OPTIMISM_MINTABLE_ERC721_FACTORY);
        } else if (digest == keccak256(bytes("L1Block"))) {
            return payable(Predeploys.L1_BLOCK_ATTRIBUTES);
        } else if (digest == keccak256(bytes("GasPriceOracle"))) {
            return payable(Predeploys.GAS_PRICE_ORACLE);
        } else if (digest == keccak256(bytes("L1MessageSender"))) {
            return payable(Predeploys.L1_MESSAGE_SENDER);
        } else if (digest == keccak256(bytes("DeployerWhitelist"))) {
            return payable(Predeploys.DEPLOYER_WHITELIST);
        } else if (digest == keccak256(bytes("WETH9"))) {
            return payable(Predeploys.WETH9);
        } else if (digest == keccak256(bytes("LegacyERC20ETH"))) {
            return payable(Predeploys.LEGACY_ERC20_ETH);
        } else if (digest == keccak256(bytes("L1BlockNumber"))) {
            return payable(Predeploys.L1_BLOCK_NUMBER);
        } else if (digest == keccak256(bytes("LegacyMessagePasser"))) {
            return payable(Predeploys.LEGACY_MESSAGE_PASSER);
        } else if (digest == keccak256(bytes("ProxyAdmin"))) {
            return payable(Predeploys.PROXY_ADMIN);
        } else if (digest == keccak256(bytes("BaseFeeVault"))) {
            return payable(Predeploys.BASE_FEE_VAULT);
        } else if (digest == keccak256(bytes("L1FeeVault"))) {
            return payable(Predeploys.L1_FEE_VAULT);
        } else if (digest == keccak256(bytes("GovernanceToken"))) {
            return payable(Predeploys.GOVERNANCE_TOKEN);
        } else if (digest == keccak256(bytes("SchemaRegistry"))) {
            return payable(Predeploys.SCHEMA_REGISTRY);
        } else if (digest == keccak256(bytes("EAS"))) {
            return payable(Predeploys.EAS);
        }
        return payable(address(0));
    }

    /// @notice Returns the address of a deployment and reverts if the deployment
    ///         does not exist.
    /// @return The address of the deployment.
    function mustGetAddress(string memory _name) public view returns (address payable) {
        address addr = getAddress(_name);
        if (addr == address(0)) {
            revert DeploymentDoesNotExist(_name);
        }
        return payable(addr);
    }

    /// @notice allow to override an existing deployment by ignoring the current one.
    /// the deployment will only be overriden on disk once the broadast is performed and `forge-deploy` sync is invoked.
    /// @param name deployment's name to override
    function ignoreDeployment(string memory name) public {
        _namedDeployments[name].name = "";
        _namedDeployments[name].addr = payable(address(1)); // TO ensure it is picked up as being ignored
    }

    /// @notice Returns a deployment that is suitable to be used to interact with contracts.
    /// @param _name The name of the deployment.
    /// @return The deployment.
    function get(string memory _name) public view returns (Deployment memory) {
        return _namedDeployments[_name];
    }

    /// @notice Appends a deployment to disk as a JSON deploy artifact.
    /// @param _name The name of the deployment.
    /// @param _deployed The address of the deployment.
    function save(string memory _name, address _deployed) public {
        if (bytes(_name).length == 0) {
            revert InvalidDeployment("EmptyName");
        }
        if (bytes(_namedDeployments[_name].name).length > 0) {
            revert InvalidDeployment("AlreadyExists");
        }

        console.log("Saving %s: %s", _name, _deployed);
        Deployment memory deployment = Deployment({name: _name, addr: payable(_deployed)});
        _namedDeployments[_name] = deployment;
        _newDeployments.push(deployment);
        _appendDeployment(_name, _deployed);
    }

    // --------------------------------------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------------------------------------

    /// @notice Adds a deployment to the temp deployments file
    function _appendDeployment(string memory _name, address _deployed) internal {
        vm.writeJson({json: stdJson.serialize("", _name, _deployed), path: deploymentOutfile});
    }
}

function getDeployer() returns (IDeployer) {
    address addr = address(uint160(uint256(keccak256(abi.encode("optimism.deploy")))));
    if (addr.code.length > 0) {
        return IDeployer(addr);
    }
    Vm vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
    bytes memory code = vm.getDeployedCode("Deployer.sol:GlobalDeployer");
    vm.etch(addr, code);
    vm.allowCheatcodes(addr);
    GlobalDeployer deployer = GlobalDeployer(addr);
    deployer.init();

    return deployer;
}
