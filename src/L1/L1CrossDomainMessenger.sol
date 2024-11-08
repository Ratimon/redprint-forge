// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CrossDomainMessenger} from "@redprint-core/universal/CrossDomainMessenger.sol";
import {ISemver} from "@redprint-core/universal/interfaces/ISemver.sol";
import {Predeploys} from "@redprint-core/libraries/Predeploys.sol";
import {ISuperchainConfig} from "@redprint-core/L1/interfaces/ISuperchainConfig.sol";
import {ISystemConfig} from "@redprint-core/L1/interfaces/ISystemConfig.sol";
import {IOptimismPortal} from "@redprint-core/L1/interfaces/IOptimismPortal.sol";

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol
contract L1CrossDomainMessenger is CrossDomainMessenger, ISemver {
    /// @notice Contract of the SuperchainConfig.
    ISuperchainConfig public superchainConfig;
    /// @notice Contract of the OptimismPortal.
    /// @custom:network-specific
    IOptimismPortal public portal;
    /// @notice Address of the SystemConfig contract.
    ISystemConfig public systemConfig;
    /// @notice Semantic version.
    /// @custom:semver 2.4.1-beta.2
    string public constant version = "2.4.1-beta.2";

    constructor() CrossDomainMessenger() {
        initialize({
            _superchainConfig: ISuperchainConfig(address(0)),
            _portal: IOptimismPortal(payable(address(0))),
            _systemConfig: ISystemConfig(address(0))
        });
    }

    function initialize(ISuperchainConfig _superchainConfig, IOptimismPortal _portal, ISystemConfig _systemConfig)
        public
        initializer
    {
        superchainConfig = _superchainConfig;
        portal = _portal;
        systemConfig = _systemConfig;
        __CrossDomainMessenger_init({ _otherMessenger: CrossDomainMessenger(Predeploys.L2_CROSS_DOMAIN_MESSENGER) });
    }

    function gasPayingToken()
        internal
        view
        override
        returns (address addr_, uint8 decimals_)
    {
        (addr_, decimals_) = systemConfig.gasPayingToken();
    }

    function PORTAL() external view returns (IOptimismPortal) {
        return portal;
    }

    function _sendMessage(address _to, uint64 _gasLimit, uint256 _value, bytes memory _data)
        internal
        override
    {
        portal.depositTransaction{ value: _value }({
        _to: _to,
        _value: _value,
        _gasLimit: _gasLimit,
        _isCreation: false,
        _data: _data
    });
    }

    function _isOtherMessenger() internal view override returns (bool) {
        return msg.sender == address(portal) && portal.l2Sender() == address(otherMessenger);
    }

    function _isUnsafeTarget(address _target)
        internal
        view
        override
        returns (bool)
    {
        return _target == address(this) || _target == address(portal);
    }

    function paused() public view override returns (bool) {
        return superchainConfig.paused();
    }
}
