// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDeployer, Vm} from "@script/deployer/Deployer.sol";

struct DeployOptions {
    uint256 salt;
}

struct PrivateDeployOptions {
    bool deterministic;
    uint256 salt;
}

library DefaultDeployerFunction {
    function prepareCall(IDeployer deployer) internal {
        prepareCall(deployer, address(0));
    }

    function prepareCall(IDeployer deployer, address sender) internal {
        (bool prankActive, address prankAddress) = deployer.prankStatus();
        bool autoBroadcast = deployer.autoBroadcasting();
        if (prankActive) {
            if (prankAddress != address(0)) {
                vm.prank(prankAddress);
            } else {
                vm.prank(sender);
            }
        } else if (autoBroadcast) {
            if (sender != address(0)) {
                vm.broadcast(sender);
            } else {
                vm.broadcast();
            }
        }
    }

    /// @notice generic deploy function (to be used with Deployer)
    ///  `using DefaultDeployerFunction with Deployer;`
    /// @param deployer contract that keeps track of the deployments and saves them
    /// @param name the deployment's name that will stored on disk in `<deployments>/<context>/<name>.json`
    /// @param artifact forge's artifact path `<solidity file>.sol:<contract name>`
    /// @param args encoded arguments for the contract's constructor
    function deploy(IDeployer deployer, string memory name, string memory artifact, bytes memory args)
        internal
        returns (address payable deployed)
    {
        return _deploy(deployer, name, artifact, args, PrivateDeployOptions({deterministic: false, salt: 0}));
    }

    /// @notice generic create2 deploy function (to be used with Deployer)
    ///  `using DefaultDeployerFunction with Deployer;`
    /// @param deployer contract that keeps track of the deployments and saves them
    /// @param name the deployment's name that will stored on disk in `<deployments>/<context>/<name>.json`
    /// @param artifact forge's artifact path `<solidity file>.sol:<contract name>`
    /// @param args encoded arguments for the contract's constructor
    /// @param options to specify for salt for deterministic deployment
    function deploy(
        IDeployer deployer,
        string memory name,
        string memory artifact,
        bytes memory args,
        DeployOptions memory options
    ) internal returns (address payable deployed) {
        return _deploy(deployer, name, artifact, args, PrivateDeployOptions({deterministic: true, salt: options.salt}));
    }

    // --------------------------------------------------------------------------------------------
    // PRIVATE
    // --------------------------------------------------------------------------------------------
    Vm private constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function _deploy(
        IDeployer deployer,
        string memory name,
        string memory artifact,
        bytes memory args,
        PrivateDeployOptions memory options
    ) private returns (address payable deployed) {
        address payable existing = deployer.getAddress(name);
        if (existing == address(0)) {
            bytes memory bytecode = vm.getCode(artifact);
            bytes memory data = bytes.concat(bytecode, args);
            if (options.deterministic) {
                // TODO configure factory ... per network (like hardhat-deploy)
                // if (address(0x4e59b44847b379578588920cA78FbF26c0B4956C).code.length == 0) {
                //     vm.sendRawTransaction(
                //         hex"f8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222"
                //     );
                // }
                uint256 salt = options.salt;
                prepareCall(deployer);
                assembly {
                    deployed := create2(0, add(data, 0x20), mload(data), salt)
                }
            } else {
                prepareCall(deployer);
                assembly {
                    deployed := create(0, add(data, 0x20), mload(data))
                }
            }

            if (deployed == address(0)) {
                revert(string.concat("Failed to deploy ", name));
            }
            deployer.save(name, deployed);
        } else {
            deployed = existing;
        }
    }
}
