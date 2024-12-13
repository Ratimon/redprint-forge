// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GnosisSafe as Safe} from "@redprint-safe-contracts/GnosisSafe.sol";
import { Enum as SafeOps } from "@redprint-safe-contracts/common/Enum.sol";

import {ProxyAdmin} from "@redprint-core/universal/ProxyAdmin.sol";


abstract contract SafeScript {

    /// @notice Call from the Safe contract to the Proxy Admin's upgrade and call method
    function _upgradeAndCallViaSafe( address _owner, address _proxyAdmin, address _safe, address _proxy, address _implementation, bytes memory _innerCallData) internal {

        bytes memory data =
            abi.encodeCall(ProxyAdmin.upgradeAndCall, (payable(_proxy), _implementation, _innerCallData));

        Safe safe = Safe(payable(_safe));
        _callViaSafe({ _safe: safe, _owner: _owner, _target: _proxyAdmin, _data: data });
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
