// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SystemConfig} from "@redprint-core/L1/SystemConfig.sol";
import {ERC20} from "@redprint-openzeppelin/token/ERC20/ERC20.sol";
import {IOptimismPortalInterop as IOptimismPortal} from "@redprint-core/L1/interfaces/IOptimismPortalInterop.sol";
import {ConfigType} from "@redprint-core/L2/L1BlockInterop.sol";
import {Constants} from "@redprint-core/libraries/Constants.sol";
import {GasPayingToken} from "@redprint-core/libraries/GasPayingToken.sol";
import {StaticConfig} from "@redprint-core/libraries/StaticConfig.sol";
import {Storage} from "@redprint-core/libraries/Storage.sol";
import {IResourceMetering} from "@redprint-core/L1/interfaces/IResourceMetering.sol";

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/L1/SystemConfig.sol
contract SystemConfigInterop is SystemConfig {
    /// @notice Storage slot where the dependency manager address is stored
    /// @dev    Equal to bytes32(uint256(keccak256("systemconfig.dependencymanager")) - 1)
    bytes32 internal constant DEPENDENCY_MANAGER_SLOT =
        0x1708e077affb93e89be2665fb0fb72581be66f84dc00d25fed755ae911905b1c;

    function _setGasPayingToken(address _token) internal override {
        if (_token != address(0) && _token != Constants.ETHER && !isCustomGasToken()) {
        require(
            ERC20(_token).decimals() == GAS_PAYING_TOKEN_DECIMALS, "SystemConfig: bad decimals of gas paying token"
        );
        bytes32 name = GasPayingToken.sanitize(ERC20(_token).name());
        bytes32 symbol = GasPayingToken.sanitize(ERC20(_token).symbol());

        // Set the gas paying token in storage and in the OptimismPortal.
        GasPayingToken.set({ _token: _token, _decimals: GAS_PAYING_TOKEN_DECIMALS, _name: name, _symbol: symbol });
        IOptimismPortal(payable(optimismPortal())).setConfig(
            ConfigType.SET_GAS_PAYING_TOKEN,
            StaticConfig.encodeSetGasPayingToken({
                _token: _token,
                _decimals: GAS_PAYING_TOKEN_DECIMALS,
                _name: name,
                _symbol: symbol
            })
        );
    }
        super._setGasPayingToken(_token);
    }

    function initialize(address _owner, uint32 _basefeeScalar, uint32 _blobbasefeeScalar, bytes32 _batcherHash, uint64 _gasLimit, address _unsafeBlockSigner, IResourceMetering.ResourceConfig memory _config, address _batchInbox, SystemConfig.Addresses memory _addresses, address _dependencyManager)
        external
        initializer
    {
        // This method has an initializer modifier, and will revert if already initialized.
        initialize({
            _owner: _owner,
            _basefeeScalar: _basefeeScalar,
            _blobbasefeeScalar: _blobbasefeeScalar,
            _batcherHash: _batcherHash,
            _gasLimit: _gasLimit,
            _unsafeBlockSigner: _unsafeBlockSigner,
            _config: _config,
            _batchInbox: _batchInbox,
            _addresses: _addresses
        });
        Storage.setAddress(DEPENDENCY_MANAGER_SLOT, _dependencyManager);
    }

    function version() public pure override returns (string memory) {
        return string.concat(super.version(), "+interop-beta.3");
    }

    function addDependency(uint256 _chainId) external {
        require(msg.sender == dependencyManager(), "SystemConfig: caller is not the dependency manager");
        IOptimismPortal(payable(optimismPortal())).setConfig(
            ConfigType.ADD_DEPENDENCY, StaticConfig.encodeAddDependency(_chainId)
        );
    }

    function removeDependency(uint256 _chainId) external {
        require(msg.sender == dependencyManager(), "SystemConfig: caller is not the dependency manager");
        require(msg.sender == dependencyManager(), "SystemConfig: caller is not the dependency manager");
        IOptimismPortal(payable(optimismPortal())).setConfig(
            ConfigType.REMOVE_DEPENDENCY, StaticConfig.encodeRemoveDependency(_chainId)
        );
    }

    function dependencyManager() public view returns (address) {
        return Storage.getAddress(DEPENDENCY_MANAGER_SLOT);
    }
}
