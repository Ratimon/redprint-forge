// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISemver} from "@redprint-core/universal/interfaces/ISemver.sol";
import {Initializable} from "@redprint-openzeppelin/proxy/utils/Initializable.sol";
import {IOptimismERC20Factory} from "@redprint-core/L2/interfaces/IOptimismERC20Factory.sol";
import {OptimismMintableERC20} from "@redprint-core/universal/OptimismMintableERC20.sol";

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/universal/OptimismMintableERC20Factory.sol
contract OptimismMintableERC20Factory is Initializable, ISemver, IOptimismERC20Factory {
    /// @custom:spacer OptimismMintableERC20Factory's initializer slot spacing
    /// @notice Spacer to avoid packing into the initializer slot
    bytes30 private spacer_0_2_30;
    /// @notice Address of the StandardBridge on this chain.
    /// @custom:network-specific
    address public bridge;
    /// @notice Mapping of local token address to remote token address.
    ///         This is used to keep track of the token deployments.
    mapping(address => address) public deployments;
    /// @notice Reserve extra slots in the storage layout for future upgrades.
    ///         A gap size of 48 was chosen here, so that the first slot used in a child contract
    ///         would be a multiple of 50.
    uint256[48] private __gap;
    /// @custom:legacy
    /// @notice Emitted whenever a new OptimismMintableERC20 is created. Legacy version of the newer
    ///         OptimismMintableERC20Created event. We recommend relying on that event instead.
    /// @param remoteToken Address of the token on the remote chain.
    /// @param localToken  Address of the created token on the local chain.
    event StandardL2TokenCreated(address indexed remoteToken, address indexed localToken);
    /// @notice Emitted whenever a new OptimismMintableERC20 is created.
    /// @param localToken  Address of the created token on the local chain.
    /// @param remoteToken Address of the corresponding token on the remote chain.
    /// @param deployer    Address of the account that deployed the token.
    event OptimismMintableERC20Created(address indexed localToken, address indexed remoteToken, address deployer);
    /// @notice The semver MUST be bumped any time that there is a change in
    ///         the OptimismMintableERC20 token contract since this contract
    ///         is responsible for deploying OptimismMintableERC20 contracts.
    /// @notice Semantic version.
    /// @custom:semver 1.10.1-beta.4
    string public constant version = "1.10.1-beta.4";

    constructor() {
        initialize({ _bridge: address(0) });
    }

    function initialize(address _bridge) public initializer {
        bridge = _bridge;
    }

    function BRIDGE() external view returns (address) {
        return bridge;
    }

    function createStandardL2Token(address _remoteToken, string memory _name, string memory _symbol)
        external
        returns (address)
    {
        return createOptimismMintableERC20(_remoteToken, _name, _symbol);
    }

    function createOptimismMintableERC20(address _remoteToken, string memory _name, string memory _symbol)
        public
        returns (address)
    {
        return createOptimismMintableERC20WithDecimals(_remoteToken, _name, _symbol, 18);
    }

    function createOptimismMintableERC20WithDecimals(address _remoteToken, string memory _name, string memory _symbol, uint8 _decimals)
        public
        returns (address)
    {
        require(_remoteToken != address(0), "OptimismMintableERC20Factory: must provide remote token address");

        bytes32 salt = keccak256(abi.encode(_remoteToken, _name, _symbol, _decimals));

        address localToken =
            address(new OptimismMintableERC20{ salt: salt }(bridge, _remoteToken, _name, _symbol, _decimals));

        deployments[localToken] = _remoteToken;

        // Emit the old event too for legacy support.
        emit StandardL2TokenCreated(_remoteToken, localToken);

        // Emit the updated event. The arguments here differ from the legacy event, but
        // are consistent with the ordering used in StandardBridge events.
        emit OptimismMintableERC20Created(localToken, _remoteToken, msg.sender);

        return localToken;
    }
}
