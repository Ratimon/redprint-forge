// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@redprint-openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ISemver} from "@redprint-core/universal/interfaces/ISemver.sol";
import {Storage} from "@redprint-core/libraries/Storage.sol";

type ProtocolVersion is uint256;

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/L1/ProtocolVersions.sol
contract ProtocolVersions is OwnableUpgradeable, ISemver {
    /// @notice Enum representing different types of updates.
    /// @custom:value REQUIRED_PROTOCOL_VERSION              Represents an update to the required protocol version.
    /// @custom:value RECOMMENDED_PROTOCOL_VERSION           Represents an update to the recommended protocol version.
    enum UpdateType {
        REQUIRED_PROTOCOL_VERSION,
        RECOMMENDED_PROTOCOL_VERSION
    }
     /// @notice Version identifier, used for upgrades.
    uint256 public constant VERSION = 0;
    /// @notice Storage slot that the required protocol version is stored at.
    bytes32 public constant REQUIRED_SLOT = bytes32(uint256(keccak256("protocolversion.required")) - 1);
    /// @notice Storage slot that the recommended protocol version is stored at.
    bytes32 public constant RECOMMENDED_SLOT = bytes32(uint256(keccak256("protocolversion.recommended")) - 1);
    /// @notice Emitted when configuration is updated.
    /// @param version    ProtocolVersion version.
    /// @param updateType Type of update.
    /// @param data       Encoded update data.
    event ConfigUpdate(uint256 indexed version, UpdateType indexed updateType, bytes data);
    /// @notice Semantic version.
    /// @custom:semver 1.0.1-beta.3
    string public constant version = "1.0.1-beta.3";

    constructor() {
        initialize({
            _owner: address(0xdEaD),
            _required: ProtocolVersion.wrap(uint256(0)),
            _recommended: ProtocolVersion.wrap(uint256(0))
        });
    }

    function initialize(address _owner, ProtocolVersion _required, ProtocolVersion _recommended)
        public
        initializer
    {
        __Ownable_init();
        transferOwnership(_owner);
        _setRequired(_required);
        _setRecommended(_recommended);
    }

    function required() external view returns (ProtocolVersion out_) {
        out_ = ProtocolVersion.wrap(Storage.getUint(REQUIRED_SLOT));
    }

    function setRequired(ProtocolVersion _required) external onlyOwner {
        _setRequired(_required);
    }

    function _setRequired(ProtocolVersion _required) internal {
        Storage.setUint(REQUIRED_SLOT, ProtocolVersion.unwrap(_required));
        bytes memory data = abi.encode(_required);
        emit ConfigUpdate(VERSION, UpdateType.REQUIRED_PROTOCOL_VERSION, data);
    }

    function recommended() external view returns (ProtocolVersion out_) {
        out_ = ProtocolVersion.wrap(Storage.getUint(RECOMMENDED_SLOT));
    }

    function setRecommended(ProtocolVersion _recommended) external onlyOwner {
        _setRecommended(_recommended);
    }

    function _setRecommended(ProtocolVersion _recommended) internal {
        Storage.setUint(RECOMMENDED_SLOT, ProtocolVersion.unwrap(_recommended));

        bytes memory data = abi.encode(_recommended);
        emit ConfigUpdate(VERSION, UpdateType.RECOMMENDED_PROTOCOL_VERSION, data);
    }
}
