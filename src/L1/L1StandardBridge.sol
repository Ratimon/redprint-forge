// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StandardBridge} from "@redprint-core/universal/StandardBridge.sol";
import {ISemver} from "@redprint-core/universal/interfaces/ISemver.sol";
import {Predeploys} from "@redprint-core/libraries/Predeploys.sol";
import {ICrossDomainMessenger} from "@redprint-core/universal/interfaces/ICrossDomainMessenger.sol";
import {ISuperchainConfig} from "@redprint-core/L1/interfaces/ISuperchainConfig.sol";
import {ISystemConfig} from "@redprint-core/L1/interfaces/ISystemConfig.sol";

/// @custom:security-contact Consult full code athttps://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/L1/L1StandardBridge.sol
contract L1StandardBridge is StandardBridge, ISemver {
    /// @custom:legacy
    /// @notice Emitted whenever a deposit of ETH from L1 into L2 is initiated.
    /// @param from      Address of the depositor.
    /// @param to        Address of the recipient on L2.
    /// @param amount    Amount of ETH deposited.
    /// @param extraData Extra data attached to the deposit.
    event ETHDepositInitiated(address indexed from, address indexed to, uint256 amount, bytes extraData);

    /// @custom:legacy
    /// @notice Emitted whenever a withdrawal of ETH from L2 to L1 is finalized.
    /// @param from      Address of the withdrawer.
    /// @param to        Address of the recipient on L1.
    /// @param amount    Amount of ETH withdrawn.
    /// @param extraData Extra data attached to the withdrawal.
    event ETHWithdrawalFinalized(address indexed from, address indexed to, uint256 amount, bytes extraData);
    /// @custom:legacy
    /// @notice Emitted whenever an ERC20 deposit is initiated.
    /// @param l1Token   Address of the token on L1.
    /// @param l2Token   Address of the corresponding token on L2.
    /// @param from      Address of the depositor.
    /// @param to        Address of the recipient on L2.
    /// @param amount    Amount of the ERC20 deposited.
    /// @param extraData Extra data attached to the deposit.
    event ERC20DepositInitiated(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );
    /// @custom:legacy
    /// @notice Emitted whenever an ERC20 withdrawal is finalized.
    /// @param l1Token   Address of the token on L1.
    /// @param l2Token   Address of the corresponding token on L2.
    /// @param from      Address of the withdrawer.
    /// @param to        Address of the recipient on L1.
    /// @param amount    Amount of the ERC20 withdrawn.
    /// @param extraData Extra data attached to the withdrawal.
    event ERC20WithdrawalFinalized(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );
    /// @notice Semantic version.
    /// @custom:semver 2.2.1-beta.1
    string public constant version = "2.2.1-beta.1";
    /// @notice Address of the SuperchainConfig contract.
    ISuperchainConfig public superchainConfig;
    /// @notice Address of the SystemConfig contract.
    ISystemConfig public systemConfig;

    constructor() StandardBridge() {
        initialize({
            _messenger: ICrossDomainMessenger(address(0)),
            _superchainConfig: ISuperchainConfig(address(0)),
            _systemConfig: ISystemConfig(address(0))
        });
    }

    receive() external payable override onlyEOA {
        _initiateETHDeposit(msg.sender, msg.sender, RECEIVE_DEFAULT_GAS_LIMIT, bytes(""));
    }

    function _emitETHBridgeInitiated(address _from, address _to, uint256 _amount, bytes memory _extraData)
        internal
        override
    {
        emit ETHDepositInitiated(_from, _to, _amount, _extraData);
        super._emitETHBridgeInitiated(_from, _to, _amount, _extraData);
    }

    function _emitETHBridgeFinalized(address _from, address _to, uint256 _amount, bytes memory _extraData)
        internal
        override
    {
        emit ETHWithdrawalFinalized(_from, _to, _amount, _extraData);
        super._emitETHBridgeFinalized(_from, _to, _amount, _extraData);
    }

    function _emitERC20BridgeInitiated(address _localToken, address _remoteToken, address _from, address _to, uint256 _amount, bytes memory _extraData)
        internal
        override
    {
         emit ERC20DepositInitiated(_localToken, _remoteToken, _from, _to, _amount, _extraData);
        super._emitERC20BridgeInitiated(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }

    function _emitERC20BridgeFinalized(address _localToken, address _remoteToken, address _from, address _to, uint256 _amount, bytes memory _extraData)
        internal
        override
    {
        emit ERC20WithdrawalFinalized(_localToken, _remoteToken, _from, _to, _amount, _extraData);
        super._emitERC20BridgeFinalized(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }

    function initialize( ICrossDomainMessenger _messenger, ISuperchainConfig _superchainConfig, ISystemConfig _systemConfig)
        public
        initializer
    {
        superchainConfig = _superchainConfig;
        systemConfig = _systemConfig;
        __StandardBridge_init({
            _messenger: _messenger,
            _otherBridge: StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE))
        });
    }

    function paused() public view override returns (bool) {
        return superchainConfig.paused();
    }

    function gasPayingToken()
        internal
        view
        override
        returns (address addr_, uint8 decimals_)
    {
        (addr_, decimals_) = systemConfig.gasPayingToken();
    }

    function depositETH(uint32 _minGasLimit, bytes calldata _extraData)
        external payable
        onlyEOA
    {
        _initiateETHDeposit(msg.sender, msg.sender, _minGasLimit, _extraData);
    }

    function depositETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData)
        external payable
        onlyEOA
    {
        _initiateETHDeposit(msg.sender, _to, _minGasLimit, _extraData);
    }

    function depositERC20(address _l1Token, address _l2Token, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData)
        external
        virtual onlyEOA
    {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, msg.sender, _amount, _minGasLimit, _extraData);
    }

    function depositERC20To(address _l1Token, address _l2Token, address _to, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData)
        external
        virtual
    {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, _to, _amount, _minGasLimit, _extraData);
    }

    function finalizeETHWithdrawal(address _from, address _to, uint256 _amount, bytes calldata _extraData)
        external payable
    {
        finalizeBridgeETH(_from, _to, _amount, _extraData);
    }

    function finalizeERC20Withdrawal(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount, bytes calldata _extraData)
        external
    {
        finalizeBridgeERC20(_l1Token, _l2Token, _from, _to, _amount, _extraData);
    }

    function l2TokenBridge() external view returns (address) {
        return address(otherBridge);
    }

    function _initiateETHDeposit(address _from, address _to, uint32 _minGasLimit, bytes memory _extraData)
        internal
    {
        _initiateBridgeETH(_from, _to, msg.value, _minGasLimit, _extraData);
    }

    function _initiateERC20Deposit(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount, uint32 _minGasLimit, bytes memory _extraData)
        internal
    {
        _initiateBridgeERC20(_l1Token, _l2Token, _from, _to, _amount, _minGasLimit, _extraData);
    }
}
