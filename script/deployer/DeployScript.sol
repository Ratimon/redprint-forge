// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@redprint-forge-std/Script.sol";
import {Vm} from "@redprint-forge-std/Vm.sol";
import {Deployment, Deployment, IDeployer, getDeployer} from "@redprint-deploy/deployer/Deployer.sol";

import { Config } from "@redprint-deploy/deployer/Config.sol";

abstract contract DeployScript is Script {
    IDeployer internal deployer = getDeployer();

    function run() public virtual returns (Deployment[] memory newDeployments) {
        _deploy();

        // for each named deployer.save we got a new deployment
        // we return it so ti can get picked up by forge-deploy with the broadcasts
        return deployer.newDeployments();
    }

    function _deploy() internal {
        // TODO? pass msg.data as bytes
        // we would pass msg.data as bytes so the deploy function can make use of it if needed
        // bytes memory data = abi.encodeWithSignature("deploy(bytes)", msg.data);
        // IDEA: we could execute that version when msg.data.length > 0

        bytes memory data = abi.encodeWithSignature("deploy()");

        // we use a dynamic call to call deploy as we do not want to prescribe a return type
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (!success) {
            if (returnData.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {
                revert("FAILED_TO_CALL: deploy()");
            }
        }
    }

    /// @notice The create2 salt used for deployment of the contract implementations.
    ///         Using this helps to reduce config across networks as the implementation
    ///         addresses will be the same across networks when deployed with create2.
    function implSalt() public view returns (bytes32) {
        return keccak256(bytes(Config.implSalt()));
    }
}
