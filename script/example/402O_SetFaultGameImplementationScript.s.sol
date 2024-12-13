// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@redprint-forge-std/Script.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";

import {Types} from "@redprint-deploy/optimism/Types.sol";
import {ChainAssertions} from "@redprint-deploy/optimism/ChainAssertions.sol";

import { Chains } from "@redprint-deploy/libraries/Chains.sol";
import { Config } from "@redprint-deploy/libraries/Config.sol";
import { Process } from "@redprint-deploy/libraries/Process.sol";

import { IBigStepper } from "@redprint-core/dispute/interfaces/IBigStepper.sol";
import {  GameType, GameTypes, Claim, Duration } from "@redprint-core/dispute/lib/Types.sol";

// import {AnchorStateRegistry} from "@redprint-core/dispute/AnchorStateRegistry.sol";
import { IAnchorStateRegistry } from "@redprint-core/dispute/interfaces/IAnchorStateRegistry.sol";

import {DisputeGameFactory} from "@redprint-core/dispute/DisputeGameFactory.sol";
import { FaultDisputeGame } from "@redprint-core/dispute/FaultDisputeGame.sol";
import {IDisputeGame} from "@redprint-core/dispute/interfaces/IDisputeGame.sol";

import { PermissionedDisputeGame } from "@redprint-core/dispute/PermissionedDisputeGame.sol";
// import {DelayedWETH} from "@redprint-core/dispute/DelayedWETH.sol";
import { IDelayedWETH } from "@redprint-core/dispute/interfaces/IDelayedWETH.sol";

import { AlphabetVM } from "@redprint-test/mocks/AlphabetVM.sol";

import { IPreimageOracle } from "@redprint-core/dispute/interfaces/IBigStepper.sol";
import {PreimageOracle} from "@redprint-core/cannon/PreimageOracle.sol";

import { IDisputeGameFactory } from "@redprint-core/dispute/interfaces/IDisputeGameFactory.sol";


contract SetFaultGameImplementationScript is Script {

    IDeployer deployerProcedue;

    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));


    function run() public {

        deployerProcedue = getDeployer();
        deployerProcedue.setAutoSave(true);

        console.log("Set FaultGameImplementations Ccontract");

        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();
        if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
            console.log("Pranking owner ...");
            vm.startPrank(owner);
            setAlphabetFaultGameImplementation({ _allowUpgrade: false });
            setFastFaultGameImplementation({ _allowUpgrade: false });
            setCannonFaultGameImplementation({ _allowUpgrade: false });
            setPermissionedCannonFaultGameImplementation({ _allowUpgrade: false });
            transferDisputeGameFactoryOwnership();
            transferDelayedWETHOwnership();
  
            console.log("Pranking Stopped ...");

            vm.stopPrank();
        } else {
            console.log("Broadcasting ...");
            vm.startBroadcast(owner);
            setAlphabetFaultGameImplementation({ _allowUpgrade: false });
            setFastFaultGameImplementation({ _allowUpgrade: false });
            setCannonFaultGameImplementation({ _allowUpgrade: false });
            setPermissionedCannonFaultGameImplementation({ _allowUpgrade: false });
            transferDisputeGameFactoryOwnership();
            transferDelayedWETHOwnership();

            console.log("Broadcasted");

            vm.stopBroadcast();
        }

    }

    struct FaultDisputeGameParams {
        IAnchorStateRegistry anchorStateRegistry;
        IDelayedWETH weth;
        GameType gameType;
        Claim absolutePrestate;
        IBigStepper faultVm;
        uint256 maxGameDepth;
        Duration maxClockDuration;
    }

    function setAlphabetFaultGameImplementation(bool _allowUpgrade) internal {
        console.log("Setting Alphabet FaultDisputeGame implementation");
        DisputeGameFactory factory = DisputeGameFactory(deployerProcedue.mustGetAddress("DisputeGameFactoryProxy"));
        IDelayedWETH weth = IDelayedWETH(deployerProcedue.mustGetAddress("DelayedWETHProxy"));

        DeployConfig cfg = deployerProcedue.getConfig();

        Claim outputAbsolutePrestate = Claim.wrap(bytes32(cfg.faultGameAbsolutePrestate()));
        _setFaultGameImplementation({
            _factory: factory,
            _allowUpgrade: _allowUpgrade,
            _params: FaultDisputeGameParams({
                anchorStateRegistry: IAnchorStateRegistry(deployerProcedue.mustGetAddress("AnchorStateRegistryProxy")),
                weth: weth,
                gameType: GameTypes.ALPHABET,
                absolutePrestate: outputAbsolutePrestate,
                faultVm: IBigStepper(new AlphabetVM(outputAbsolutePrestate, IPreimageOracle(deployerProcedue.mustGetAddress("PreimageOracle")))),
                // The max depth for the alphabet trace is always 3. Add 1 because split depth is fully inclusive.
                maxGameDepth: cfg.faultGameSplitDepth() + 3 + 1,
                maxClockDuration: Duration.wrap(uint64(cfg.faultGameMaxClockDuration()))
            })
        });
    }

    function setFastFaultGameImplementation(bool _allowUpgrade) internal {
        console.log("Setting Fast FaultDisputeGame implementation");
        DisputeGameFactory factory = DisputeGameFactory(deployerProcedue.mustGetAddress("DisputeGameFactoryProxy"));
        IDelayedWETH weth = IDelayedWETH(deployerProcedue.mustGetAddress("DelayedWETHProxy"));

        DeployConfig cfg = deployerProcedue.getConfig();

        Claim outputAbsolutePrestate = Claim.wrap(bytes32(cfg.faultGameAbsolutePrestate()));
        PreimageOracle fastOracle = new PreimageOracle(cfg.preimageOracleMinProposalSize(), 0);
        _setFaultGameImplementation({
            _factory: factory,
            _allowUpgrade: _allowUpgrade,
            _params: FaultDisputeGameParams({
                anchorStateRegistry: IAnchorStateRegistry(deployerProcedue.mustGetAddress("AnchorStateRegistryProxy")),
                weth: weth,
                gameType: GameTypes.FAST,
                absolutePrestate: outputAbsolutePrestate,
                faultVm: IBigStepper(new AlphabetVM(outputAbsolutePrestate, IPreimageOracle(address(fastOracle)))),
                // The max depth for the alphabet trace is always 3. Add 1 because split depth is fully inclusive.
                maxGameDepth: cfg.faultGameSplitDepth() + 3 + 1,
                maxClockDuration: Duration.wrap(0) // Resolvable immediately
             })
        });
    }

    function setCannonFaultGameImplementation(bool _allowUpgrade) internal {
        console.log("Setting Cannon FaultDisputeGame implementation");
        DisputeGameFactory factory = DisputeGameFactory(deployerProcedue.mustGetAddress("DisputeGameFactoryProxy"));
        IDelayedWETH weth = IDelayedWETH(deployerProcedue.mustGetAddress("DelayedWETHProxy"));

        DeployConfig cfg = deployerProcedue.getConfig();

        // Set the Cannon FaultDisputeGame implementation in the factory.
        _setFaultGameImplementation({
            _factory: factory,
            _allowUpgrade: _allowUpgrade,
            _params: FaultDisputeGameParams({
                anchorStateRegistry: IAnchorStateRegistry(deployerProcedue.mustGetAddress("AnchorStateRegistryProxy")),
                weth: weth,
                gameType: GameTypes.CANNON,
                absolutePrestate: loadMipsAbsolutePrestate(),
                faultVm: IBigStepper(deployerProcedue.mustGetAddress("Mips")),
                maxGameDepth: cfg.faultGameMaxDepth(),
                maxClockDuration: Duration.wrap(uint64(cfg.faultGameMaxClockDuration()))
            })
        });
    }

    function setPermissionedCannonFaultGameImplementation(bool _allowUpgrade) internal {
        console.log("Setting Cannon PermissionedDisputeGame implementation");
        DisputeGameFactory factory = DisputeGameFactory(deployerProcedue.mustGetAddress("DisputeGameFactoryProxy"));
        IDelayedWETH weth = IDelayedWETH(deployerProcedue.mustGetAddress("PermissionedDelayedWETHProxy"));

        DeployConfig cfg = deployerProcedue.getConfig();

        // Set the Cannon FaultDisputeGame implementation in the factory.
        _setFaultGameImplementation({
            _factory: factory,
            _allowUpgrade: _allowUpgrade,
            _params: FaultDisputeGameParams({
                anchorStateRegistry: IAnchorStateRegistry(deployerProcedue.mustGetAddress("AnchorStateRegistryProxy")),
                weth: weth,
                gameType: GameTypes.PERMISSIONED_CANNON,
                absolutePrestate: loadMipsAbsolutePrestate(),
                faultVm: IBigStepper(deployerProcedue.mustGetAddress("Mips")),
                maxGameDepth: cfg.faultGameMaxDepth(),
                maxClockDuration: Duration.wrap(uint64(cfg.faultGameMaxClockDuration()))
            })
        });
    }

    function transferDisputeGameFactoryOwnership() internal {
        console.log("Transferring DisputeGameFactory ownership to Safe");
        IDisputeGameFactory disputeGameFactory = IDisputeGameFactory(deployerProcedue.mustGetAddress("DisputeGameFactoryProxy"));
        address _owner = disputeGameFactory.owner();

        DeployConfig cfg = deployerProcedue.getConfig();
        address finalSystemOwner = cfg.finalSystemOwner();

        if (_owner != finalSystemOwner) {
            disputeGameFactory.transferOwnership(finalSystemOwner);
            console.log("DisputeGameFactory ownership transferred to final system owner at: %s", finalSystemOwner);
        }

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkDisputeGameFactory({
            _contracts: proxies,
            _expectedOwner: finalSystemOwner,
            _isProxy: true
        });
    }

    function transferDelayedWETHOwnership() internal {
        console.log("Transferring DelayedWETH ownership to Safe");
        IDelayedWETH weth = IDelayedWETH(deployerProcedue.mustGetAddress("DelayedWETHProxy"));
        address _owner = weth.owner();

        DeployConfig cfg = deployerProcedue.getConfig();
        address finalSystemOwner = cfg.finalSystemOwner();
        if (_owner != finalSystemOwner) {
            weth.transferOwnership(finalSystemOwner);
            console.log("DelayedWETH ownership transferred to final system owner at: %s", finalSystemOwner);
        }

        Types.ContractSet memory proxies =  deployerProcedue.getProxies();
        ChainAssertions.checkDelayedWETH({
            _contracts: proxies,
            _cfg: cfg,
            _isProxy: true,
            _expectedOwner: finalSystemOwner
        });
    }

    function loadMipsAbsolutePrestate() internal returns (Claim mipsAbsolutePrestate_) {

        DeployConfig cfg = deployerProcedue.getConfig();

        if (block.chainid == Chains.LocalDevnet || block.chainid == Chains.GethDevnet) {
            if (Config.useMultithreadedCannon()) {
                return _loadDevnetMtMipsAbsolutePrestate();
            } else {
                return _loadDevnetStMipsAbsolutePrestate();
            }
        } else {
            console.log(
                "[Cannon Dispute Game] Using absolute prestate from config: %x", cfg.faultGameAbsolutePrestate()
            );
            mipsAbsolutePrestate_ = Claim.wrap(bytes32(cfg.faultGameAbsolutePrestate()));
        }
    }

    function _loadDevnetMtMipsAbsolutePrestate() internal returns (Claim mipsAbsolutePrestate_) {
        // Fetch the absolute prestate dump
        string memory filePath = string.concat(vm.projectRoot(), "/../op-program/bin/prestate-proof-mt.json");
        string[] memory commands = new string[](3);
        commands[0] = "bash";
        commands[1] = "-c";
        commands[2] = string.concat("[[ -f ", filePath, " ]] && echo \"present\"");
        if (Process.run(commands).length == 0) {
            revert(
                "Deploy: MT-Cannon prestate dump not found, generate it with `make cannon-prestate-mt` in the monorepo root"
            );
        }
        commands[2] = string.concat("cat ", filePath, " | jq -r .pre");
        mipsAbsolutePrestate_ = Claim.wrap(abi.decode(Process.run(commands), (bytes32)));
        console.log(
            "[MT-Cannon Dispute Game] Using devnet MIPS2 Absolute prestate: %s",
            vm.toString(Claim.unwrap(mipsAbsolutePrestate_))
        );
    }

    function _loadDevnetStMipsAbsolutePrestate() internal returns (Claim mipsAbsolutePrestate_) {
        // Fetch the absolute prestate dump
        string memory filePath = string.concat(vm.projectRoot(), "/../op-program/bin/prestate-proof.json");
        string[] memory commands = new string[](3);
        commands[0] = "bash";
        commands[1] = "-c";
        commands[2] = string.concat("[[ -f ", filePath, " ]] && echo \"present\"");
        if (Process.run(commands).length == 0) {
            revert(
                "Deploy: cannon prestate dump not found, generate it with `make cannon-prestate` in the monorepo root"
            );
        }
        commands[2] = string.concat("cat ", filePath, " | jq -r .pre");
        mipsAbsolutePrestate_ = Claim.wrap(abi.decode(Process.run(commands), (bytes32)));
        console.log(
            "[Cannon Dispute Game] Using devnet MIPS Absolute prestate: %s",
            vm.toString(Claim.unwrap(mipsAbsolutePrestate_))
        );
    }

    /// @notice Sets the implementation for the given fault game type in the `DisputeGameFactory`.
    function _setFaultGameImplementation(
        DisputeGameFactory _factory,
        bool _allowUpgrade,
        FaultDisputeGameParams memory _params
    )
        internal
    {
        if (address(_factory.gameImpls(_params.gameType)) != address(0) && !_allowUpgrade) {
            console.log(
                "[WARN] DisputeGameFactoryProxy: `FaultDisputeGame` implementation already set for game type: %s",
                vm.toString(GameType.unwrap(_params.gameType))
            );
            return;
        }

        DeployConfig cfg = deployerProcedue.getConfig();
        uint32 rawGameType = GameType.unwrap(_params.gameType);
        if (rawGameType != GameTypes.PERMISSIONED_CANNON.raw()) {

            address faultDisputeGameAddress = address(new FaultDisputeGame({
                _gameType: _params.gameType,
                _absolutePrestate: _params.absolutePrestate,
                _maxGameDepth: _params.maxGameDepth,
                _splitDepth: cfg.faultGameSplitDepth(),
                _clockExtension: Duration.wrap(uint64(cfg.faultGameClockExtension())),
                _maxClockDuration: _params.maxClockDuration,
                _vm: _params.faultVm,
                _weth: _params.weth,
                _anchorStateRegistry: _params.anchorStateRegistry,
                _l2ChainId: cfg.l2ChainID()
            }));

            _factory.setImplementation(
                _params.gameType,
                IDisputeGame(faultDisputeGameAddress)
            );
           
        } else {
            address permissionedDisputeGameAddress = address(new PermissionedDisputeGame({
                    _gameType: _params.gameType,
                    _absolutePrestate: _params.absolutePrestate,
                    _maxGameDepth: _params.maxGameDepth,
                    _splitDepth: cfg.faultGameSplitDepth(),
                    _clockExtension: Duration.wrap(uint64(cfg.faultGameClockExtension())),
                    _maxClockDuration: Duration.wrap(uint64(cfg.faultGameMaxClockDuration())),
                    _vm: _params.faultVm,
                    _weth: _params.weth,
                    _anchorStateRegistry: _params.anchorStateRegistry,
                    _l2ChainId: cfg.l2ChainID(),
                    _proposer: cfg.l2OutputOracleProposer(),
                    _challenger: cfg.l2OutputOracleChallenger()
            }));
            
            _factory.setImplementation(
                _params.gameType,
                IDisputeGame(permissionedDisputeGameAddress)
            );
        }

        string memory gameTypeString;
        if (rawGameType == GameTypes.CANNON.raw()) {
            gameTypeString = "Cannon";
        } else if (rawGameType == GameTypes.PERMISSIONED_CANNON.raw()) {
            gameTypeString = "PermissionedCannon";
        } else if (rawGameType == GameTypes.ALPHABET.raw()) {
            gameTypeString = "Alphabet";
        } else {
            gameTypeString = "Unknown";
        }

        console.log(
            "DisputeGameFactoryProxy: set `FaultDisputeGame` implementation (Backend: %s | GameType: %s)",
            gameTypeString,
            vm.toString(rawGameType)
        );
    }

}
