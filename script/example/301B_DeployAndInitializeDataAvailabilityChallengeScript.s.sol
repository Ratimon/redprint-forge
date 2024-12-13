// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript, IDeployer} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, DeployOptions} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {DeployConfig} from "@redprint-deploy/deployer/DeployConfig.s.sol";


import {SafeScript} from "@redprint-deploy/safe-management/SafeScript.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";


import {DataAvailabilityChallenge} from "@redprint-core/L1/DataAvailabilityChallenge.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployAndInitializeDataAvailabilityChallengeScript is DeployScript, SafeScript {
    using DeployerFunctions for IDeployer ;

    DataAvailabilityChallenge dataAvailabilityChallenge;

    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));


    function deploy() external returns (DataAvailabilityChallenge) {

        bytes32 _salt = DeployScript.implSalt();
        DeployOptions memory options = DeployOptions({salt:_salt});

        dataAvailabilityChallenge = deployer.deploy_DataAvailabilityChallenge("DataAvailabilityChallenge", options);

        return dataAvailabilityChallenge;
    }

    function initialize() external {
        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();
        if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
            console.log("Pranking owner ...");
            vm.startPrank(owner);
            initializeDataAvailabilityChallenge();
            vm.stopPrank();
        } else {
            console.log("Broadcasting ...");
            vm.startBroadcast(owner);

            initializeDataAvailabilityChallenge();
            console.log("DataAvailabilityChallenge setted to : %s", address(dataAvailabilityChallenge));

            vm.stopBroadcast();
        }
    }

    function initializeDataAvailabilityChallenge() public {
        console.log("Upgrading and initializing DataAvailabilityChallenge proxy");

        address proxyAdmin = deployer.mustGetAddress("ProxyAdmin");
        address safe = deployer.mustGetAddress("SystemOwnerSafe");

        address dataAvailabilityChallengeProxy = deployer.mustGetAddress("DataAvailabilityChallengeProxy");

        DeployConfig cfg = deployer.getConfig();

        address finalSystemOwner = cfg.finalSystemOwner();
        uint256 daChallengeWindow = cfg.daChallengeWindow();
        uint256 daResolveWindow = cfg.daResolveWindow();
        uint256 daBondSize = cfg.daBondSize();
        uint256 daResolverRefundPercentage = cfg.daResolverRefundPercentage();

        _upgradeAndCallViaSafe({
            _proxyAdmin: proxyAdmin,
            _safe: safe,
            _owner: owner,
            _proxy: payable(dataAvailabilityChallengeProxy),
            _implementation: address(dataAvailabilityChallenge),
            _innerCallData: abi.encodeCall(
                DataAvailabilityChallenge.initialize,
                (finalSystemOwner, daChallengeWindow, daResolveWindow, daBondSize, daResolverRefundPercentage)
            )
        });

        DataAvailabilityChallenge dac = DataAvailabilityChallenge(payable(dataAvailabilityChallengeProxy));
        string memory version = dac.version();
        console.log("DataAvailabilityChallenge version: %s", version);

        require(dac.owner() == finalSystemOwner);
        require(dac.challengeWindow() == daChallengeWindow);
        require(dac.resolveWindow() == daResolveWindow);
        require(dac.bondSize() == daBondSize);
        require(dac.resolverRefundPercentage() == daResolverRefundPercentage);

    }
}
