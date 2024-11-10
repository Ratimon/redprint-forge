// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721Bridge} from "@redprint-core/universal/ERC721Bridge.sol";
import {ISemver} from "@redprint-core/universal/interfaces/ISemver.sol";
import {Predeploys} from "@redprint-core/libraries/Predeploys.sol";
import {IERC721} from "@redprint-openzeppelin/token/ERC721/IERC721.sol";
import {ICrossDomainMessenger} from "@redprint-core/universal/interfaces/ICrossDomainMessenger.sol";
import {ISuperchainConfig} from "@redprint-core/L1/interfaces/ISuperchainConfig.sol";
import {IL2ERC721Bridge} from "@redprint-core/L2/interfaces/IL2ERC721Bridge.sol";

/// @custom:security-contact Consult full code athttps://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol
contract L1ERC721Bridge is ERC721Bridge, ISemver {
    /// @notice Mapping of L1 token to L2 token to ID to boolean, indicating if the given L1 token
    ///         by ID was deposited for a given L2 token.
    mapping(address => mapping(address => mapping(uint256 => bool))) public deposits;
    /// @notice Address of the SuperchainConfig contract.
    ISuperchainConfig public superchainConfig;
    /// @notice Semantic version.
    /// @custom:semver 2.1.1-beta.4
    string public constant version = "2.1.1-beta.4";

    constructor() ERC721Bridge() {
        initialize({ _messenger: ICrossDomainMessenger(address(0)), _superchainConfig: ISuperchainConfig(address(0)) });
    }

    function initialize( ICrossDomainMessenger _messenger, ISuperchainConfig _superchainConfig)
        public
        initializer
    {
        superchainConfig = _superchainConfig;
        __ERC721Bridge_init({ _messenger: _messenger, _otherBridge: ERC721Bridge(payable(Predeploys.L2_ERC721_BRIDGE)) });
    }

    function finalizeBridgeERC721(address _localToken, address _remoteToken, address _from, address _to, uint256 _tokenId, bytes calldata _extraData)
        external
        onlyOtherBridge
    {
        require(paused() == false, "L1ERC721Bridge: paused");
        require(_localToken != address(this), "L1ERC721Bridge: local token cannot be self");

        // Checks that the L1/L2 NFT pair has a token ID that is escrowed in the L1 Bridge.
        require(
            deposits[_localToken][_remoteToken][_tokenId] == true,
            "L1ERC721Bridge: Token ID is not escrowed in the L1 Bridge"
        );

        // Mark that the token ID for this L1/L2 token pair is no longer escrowed in the L1
        // Bridge.
        deposits[_localToken][_remoteToken][_tokenId] = false;

        // When a withdrawal is finalized on L1, the L1 Bridge transfers the NFT to the
        // withdrawer.
        IERC721(_localToken).safeTransferFrom({ from: address(this), to: _to, tokenId: _tokenId });

        // slither-disable-next-line reentrancy-events
        emit ERC721BridgeFinalized(_localToken, _remoteToken, _from, _to, _tokenId, _extraData);
    }

    function _initiateBridgeERC721(address _localToken, address _remoteToken, address _from, address _to, uint256 _tokenId, uint32 _minGasLimit, bytes calldata _extraData)
        internal
        override
    {
        require(_remoteToken != address(0), "L1ERC721Bridge: remote token cannot be address(0)");

        // Construct calldata for _l2Token.finalizeBridgeERC721(_to, _tokenId)
        bytes memory message = abi.encodeWithSelector(
            IL2ERC721Bridge.finalizeBridgeERC721.selector, _remoteToken, _localToken, _from, _to, _tokenId, _extraData
        );

        // Lock token into bridge
        deposits[_localToken][_remoteToken][_tokenId] = true;
        IERC721(_localToken).transferFrom({ from: _from, to: address(this), tokenId: _tokenId });

        // Send calldata into L2
        messenger.sendMessage({ _target: address(otherBridge), _message: message, _minGasLimit: _minGasLimit });
        emit ERC721BridgeInitiated(_localToken, _remoteToken, _from, _to, _tokenId, _extraData);
    }
}
