// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDeployer} from "@script/deployer/DeployScript.sol";

import { Safe } from "@safe-contracts/Safe.sol";
import { Enum as SafeOps } from "@safe-contracts/common/Enum.sol";

import {ProxyAdmin} from "@main/universal/ProxyAdmin.sol";


abstract contract SafeScript {

    /// @notice Call from the Safe contract to the Proxy Admin's upgrade and call method
    function _upgradeAndCallViaSafe(IDeployer _deployer, address _owner, address _proxy, address _implementation, bytes memory _innerCallData) internal {

        address proxyAdmin = _deployer.mustGetAddress("ProxyAdmin");

        bytes memory data =
            abi.encodeCall(ProxyAdmin.upgradeAndCall, (payable(_proxy), _implementation, _innerCallData));

        Safe safe = Safe(_deployer.mustGetAddress("SystemOwnerSafe"));
        _callViaSafe({ _safe: safe, _owner: _owner, _target: proxyAdmin, _data: data });
    }

    /// @notice Make a call from the Safe contract to an arbitrary address with arbitrary data
    function _callViaSafe(Safe _safe, address _owner, address _target, bytes memory _data) internal {

        // This is the signature format used the caller is also the signer.
        bytes memory signature = abi.encodePacked(uint256(uint160(_owner)), bytes32(0), uint8(1));

        _safe.execTransaction({
            to: _target,
            value: 0,
            data: _data,
            operation: SafeOps.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: signature
        });

    }


}
