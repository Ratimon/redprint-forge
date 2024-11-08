// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@redprint-openzeppelin-upgradable/access/OwnableUpgradeable.sol";
import {IGasToken, GasPayingToken} from "@redprint-core/libraries/GasPayingToken.sol";
import {ISemver} from "@redprint-core/universal/interfaces/ISemver.sol";
import {ERC20} from "@redprint-openzeppelin/token/ERC20/ERC20.sol";
import {Storage} from "@redprint-core/libraries/Storage.sol";
import {Constants} from "@redprint-core/libraries/Constants.sol";
import {IOptimismPortal} from "@redprint-core/L1/interfaces/IOptimismPortal.sol";
import {IResourceMetering} from "@redprint-core/L1/interfaces/IResourceMetering.sol";

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/L1/SystemConfig.sol
contract SystemConfig is OwnableUpgradeable, IGasToken, ISemver {
    /// @notice Enum representing different types of updates.
    /// @custom:value BATCHER              Represents an update to the batcher hash.
    /// @custom:value FEE_SCALARS          Represents an update to l1 data fee scalars.
    /// @custom:value GAS_LIMIT            Represents an update to gas limit on L2.
    /// @custom:value UNSAFE_BLOCK_SIGNER  Represents an update to the signer key for unsafe
    ///                                    block distrubution.
    enum UpdateType {
        BATCHER,
        FEE_SCALARS,
        GAS_LIMIT,
        UNSAFE_BLOCK_SIGNER,
        EIP_1559_PARAMS
    }
    /// @notice Struct representing the addresses of L1 system contracts. These should be the
    ///         contracts that users interact with (not implementations for proxied contracts)
    ///         and are network specific.
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address disputeGameFactory;
        address optimismPortal;
        address optimismMintableERC20Factory;
        address gasPayingToken;
    }
    /// @notice Version identifier, used for upgrades.
    uint256 public constant VERSION = 0;
    /// @notice Storage slot that the unsafe block signer is stored at.
    ///         Storing it at this deterministic storage slot allows for decoupling the storage
    ///         layout from the way that "solc" lays out storage. The "op-node" uses a storage
    ///         proof to fetch this value.
    /// @dev    NOTE: this value will be migrated to another storage slot in a future version.
    ///         User input should not be placed in storage in this contract until this migration
    ///         happens. It is unlikely that keccak second preimage resistance will be broken,
    ///         but it is better to be safe than sorry.
    bytes32 public constant UNSAFE_BLOCK_SIGNER_SLOT = keccak256("systemconfig.unsafeblocksigner");
    /// @notice Storage slot that the L1CrossDomainMessenger address is stored at.
    bytes32 public constant L1_CROSS_DOMAIN_MESSENGER_SLOT =
        bytes32(uint256(keccak256("systemconfig.l1crossdomainmessenger")) - 1);
    /// @notice Storage slot that the L1ERC721Bridge address is stored at.
    bytes32 public constant L1_ERC_721_BRIDGE_SLOT = bytes32(uint256(keccak256("systemconfig.l1erc721bridge")) - 1);
    /// @notice Storage slot that the L1StandardBridge address is stored at.
    bytes32 public constant L1_STANDARD_BRIDGE_SLOT = bytes32(uint256(keccak256("systemconfig.l1standardbridge")) - 1);
    /// @notice Storage slot that the OptimismPortal address is stored at.
    bytes32 public constant OPTIMISM_PORTAL_SLOT = bytes32(uint256(keccak256("systemconfig.optimismportal")) - 1);
    /// @notice Storage slot that the OptimismMintableERC20Factory address is stored at.
    bytes32 public constant OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT =
        bytes32(uint256(keccak256("systemconfig.optimismmintableerc20factory")) - 1);
    /// @notice Storage slot that the batch inbox address is stored at.
    bytes32 public constant BATCH_INBOX_SLOT = bytes32(uint256(keccak256("systemconfig.batchinbox")) - 1);
    /// @notice Storage slot for block at which the op-node can start searching for logs from.
    bytes32 public constant START_BLOCK_SLOT = bytes32(uint256(keccak256("systemconfig.startBlock")) - 1);
    /// @notice Storage slot for the DisputeGameFactory address.
    bytes32 public constant DISPUTE_GAME_FACTORY_SLOT =
        bytes32(uint256(keccak256("systemconfig.disputegamefactory")) - 1);
    /// @notice The number of decimals that the gas paying token has.
    uint8 internal constant GAS_PAYING_TOKEN_DECIMALS = 18;
    /// @notice The maximum gas limit that can be set for L2 blocks. This limit is used to enforce that the blocks
    ///         on L2 are not too large to process and prove. Over time, this value can be increased as various
    ///         optimizations and improvements are made to the system at large.
    uint64 internal constant MAX_GAS_LIMIT = 200_000_000;
    /// @notice Fixed L2 gas overhead. Used as part of the L2 fee calculation.
    ///         Deprecated since the Ecotone network upgrade
    uint256 public overhead;
    /// @notice Dynamic L2 gas overhead. Used as part of the L2 fee calculation.
    ///         The most significant byte is used to determine the version since the
    ///         Ecotone network upgrade.
    uint256 public scalar;
    /// @notice Identifier for the batcher.
    ///         For version 1 of this configuration, this is represented as an address left-padded
    ///         with zeros to 32 bytes.
    bytes32 public batcherHash;
    /// @notice L2 block gas limit.
    uint64 public gasLimit;
    /// @notice Basefee scalar value. Part of the L2 fee calculation since the Ecotone network upgrade.
    uint32 public basefeeScalar;
    /// @notice Blobbasefee scalar value. Part of the L2 fee calculation since the Ecotone network upgrade.
    uint32 public blobbasefeeScalar;
    /// @notice The configuration for the deposit fee market.
    ///         Used by the OptimismPortal to meter the cost of buying L2 gas on L1.
    ///         Set as internal with a getter so that the struct is returned instead of a tuple.
    IResourceMetering.ResourceConfig internal _resourceConfig;
    /// @notice The EIP-1559 base fee max change denominator.
    uint32 public eip1559Denominator;
    /// @notice The EIP-1559 elasticity multiplier.
    uint32 public eip1559Elasticity;
    /// @notice Emitted when configuration is updated.
    /// @param version    SystemConfig version.
    /// @param updateType Type of update.
    /// @param data       Encoded update data.
    event ConfigUpdate(uint256 indexed version, UpdateType indexed updateType, bytes data);

    constructor() {
        Storage.setUint(START_BLOCK_SLOT, type(uint256).max);
        initialize({
            _owner: address(0xdEaD),
            _basefeeScalar: 0,
            _blobbasefeeScalar: 0,
            _batcherHash: bytes32(0),
            _gasLimit: 1,
            _unsafeBlockSigner: address(0),
            _config: IResourceMetering.ResourceConfig({
                maxResourceLimit: 1,
                elasticityMultiplier: 1,
                baseFeeMaxChangeDenominator: 2,
                minimumBaseFee: 0,
                systemTxMaxGas: 0,
                maximumBaseFee: 0
            }),
            _batchInbox: address(0),
            _addresses: SystemConfig.Addresses({
                l1CrossDomainMessenger: address(0),
                l1ERC721Bridge: address(0),
                l1StandardBridge: address(0),
                disputeGameFactory: address(0),
                optimismPortal: address(0),
                optimismMintableERC20Factory: address(0),
                gasPayingToken: address(0)
            })
        });
    }

    function version() public pure virtual returns (string memory) {
        return "2.3.0-beta.5";
    }

    function initialize(address _owner, uint32 _basefeeScalar, uint32 _blobbasefeeScalar, bytes32 _batcherHash, uint64 _gasLimit, address _unsafeBlockSigner, IResourceMetering.ResourceConfig memory _config, address _batchInbox, SystemConfig.Addresses memory _addresses)
        public
        initializer
    {
        __Ownable_init();
        transferOwnership(_owner);

        // These are set in ascending order of their UpdateTypes.
        _setBatcherHash(_batcherHash);
        _setGasConfigEcotone({ _basefeeScalar: _basefeeScalar, _blobbasefeeScalar: _blobbasefeeScalar });
        _setGasLimit(_gasLimit);

        Storage.setAddress(UNSAFE_BLOCK_SIGNER_SLOT, _unsafeBlockSigner);
        Storage.setAddress(BATCH_INBOX_SLOT, _batchInbox);
        Storage.setAddress(L1_CROSS_DOMAIN_MESSENGER_SLOT, _addresses.l1CrossDomainMessenger);
        Storage.setAddress(L1_ERC_721_BRIDGE_SLOT, _addresses.l1ERC721Bridge);
        Storage.setAddress(L1_STANDARD_BRIDGE_SLOT, _addresses.l1StandardBridge);
        Storage.setAddress(DISPUTE_GAME_FACTORY_SLOT, _addresses.disputeGameFactory);
        Storage.setAddress(OPTIMISM_PORTAL_SLOT, _addresses.optimismPortal);
        Storage.setAddress(OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT, _addresses.optimismMintableERC20Factory);

        _setStartBlock();
        _setGasPayingToken(_addresses.gasPayingToken);

        _setResourceConfig(_config);
        require(_gasLimit >= minimumGasLimit(), "SystemConfig: gas limit too low");
    }

    function minimumGasLimit() public view returns (uint64) {
        return uint64(_resourceConfig.maxResourceLimit) + uint64(_resourceConfig.systemTxMaxGas);
    }

    function maximumGasLimit() public pure returns (uint64) {
         return MAX_GAS_LIMIT;
    }

    function unsafeBlockSigner() public view returns (address addr_) {
        addr_ = Storage.getAddress(UNSAFE_BLOCK_SIGNER_SLOT);
    }

    function l1CrossDomainMessenger() external view returns (address addr_) {
        addr_ = Storage.getAddress(L1_CROSS_DOMAIN_MESSENGER_SLOT);
    }

    function l1ERC721Bridge() external view returns (address addr_) {
        addr_ = Storage.getAddress(L1_ERC_721_BRIDGE_SLOT);
    }

    function l1StandardBridge() external view returns (address addr_) {
        addr_ = Storage.getAddress(L1_STANDARD_BRIDGE_SLOT);
    }

    function disputeGameFactory() external view returns (address addr_) {
        addr_ = Storage.getAddress(DISPUTE_GAME_FACTORY_SLOT);
    }

    function optimismPortal() public view returns (address addr_) {
        addr_ = Storage.getAddress(OPTIMISM_PORTAL_SLOT);
    }

    function optimismMintableERC20Factory() external view returns (address addr_) {
        addr_ = Storage.getAddress(OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT);
    }

    function batchInbox() external view returns (address addr_) {
        addr_ = Storage.getAddress(BATCH_INBOX_SLOT);
    }

    function startBlock() external view returns (uint256) {
        return Storage.getUint(START_BLOCK_SLOT);
    }

    function gasPayingToken()
        public
        view
        returns (address addr_, uint8 decimals_)
    {
        (addr_, decimals_) = GasPayingToken.getToken();
    }

    function isCustomGasToken() public view returns (bool) {
        (address token,) = gasPayingToken();
        return token != Constants.ETHER;
    }

    function gasPayingTokenName() external view returns (string memory name_) {
        name_ = GasPayingToken.getName();
    }

    function gasPayingTokenSymbol() external view returns (string memory symbol_) {
        symbol_ = GasPayingToken.getSymbol();
    }

    function _setGasPayingToken(address _token) internal virtual {
        if (_token != address(0) && _token != Constants.ETHER && !isCustomGasToken()) {
            require(
                ERC20(_token).decimals() == GAS_PAYING_TOKEN_DECIMALS, "SystemConfig: bad decimals of gas paying token"
            );
            bytes32 name = GasPayingToken.sanitize(ERC20(_token).name());
            bytes32 symbol = GasPayingToken.sanitize(ERC20(_token).symbol());

            // Set the gas paying token in storage and in the OptimismPortal.
            GasPayingToken.set({ _token: _token, _decimals: GAS_PAYING_TOKEN_DECIMALS, _name: name, _symbol: symbol });
            IOptimismPortal(payable(optimismPortal())).setGasPayingToken({
                _token: _token,
                _decimals: GAS_PAYING_TOKEN_DECIMALS,
                _name: name,
                _symbol: symbol
            });
        }
    }

    function setUnsafeBlockSigner(address _unsafeBlockSigner) external onlyOwner {
        _setUnsafeBlockSigner(_unsafeBlockSigner);
    }

    function _setUnsafeBlockSigner(address _unsafeBlockSigner) internal {
        Storage.setAddress(UNSAFE_BLOCK_SIGNER_SLOT, _unsafeBlockSigner);

        bytes memory data = abi.encode(_unsafeBlockSigner);
        emit ConfigUpdate(VERSION, UpdateType.UNSAFE_BLOCK_SIGNER, data);
    }

    function setBatcherHash(bytes32 _batcherHash) external onlyOwner {
        _setBatcherHash(_batcherHash);
    }

    function _setBatcherHash(bytes32 _batcherHash) internal {
        batcherHash = _batcherHash;

        bytes memory data = abi.encode(_batcherHash);
        emit ConfigUpdate(VERSION, UpdateType.BATCHER, data);
    }

    function setGasConfig(uint256 _overhead, uint256 _scalar) external onlyOwner {
        _setGasConfig(_overhead, _scalar);
    }

    function _setGasConfig(uint256 _overhead, uint256 _scalar) internal {
        require((uint256(0xff) << 248) & _scalar == 0, "SystemConfig: scalar exceeds max.");

        overhead = _overhead;
        scalar = _scalar;

        bytes memory data = abi.encode(_overhead, _scalar);
        emit ConfigUpdate(VERSION, UpdateType.FEE_SCALARS, data);
    }

    function setGasConfigEcotone(uint32 _basefeeScalar, uint32 _blobbasefeeScalar)
        external
        onlyOwner
    {
        _setGasConfigEcotone(_basefeeScalar, _blobbasefeeScalar);
    }

    function _setGasConfigEcotone(uint32 _basefeeScalar, uint32 _blobbasefeeScalar)
        internal
    {
        basefeeScalar = _basefeeScalar;
        blobbasefeeScalar = _blobbasefeeScalar;

        scalar = (uint256(0x01) << 248) | (uint256(_blobbasefeeScalar) << 32) | _basefeeScalar;

        bytes memory data = abi.encode(overhead, scalar);
        emit ConfigUpdate(VERSION, UpdateType.FEE_SCALARS, data);
    }

    function setGasLimit(uint64 _gasLimit) external onlyOwner {
        _setGasLimit(_gasLimit);
    }

    function _setGasLimit(uint64 _gasLimit) internal {
        require(_gasLimit >= minimumGasLimit(), "SystemConfig: gas limit too low");
        require(_gasLimit <= maximumGasLimit(), "SystemConfig: gas limit too high");
        gasLimit = _gasLimit;

        bytes memory data = abi.encode(_gasLimit);
        emit ConfigUpdate(VERSION, UpdateType.GAS_LIMIT, data);
    }

    function setEIP1559Params(uint32 _denominator, uint32 _elasticity)
        external
        onlyOwner
    {
        _setEIP1559Params(_denominator, _elasticity);
    }

    function _setEIP1559Params(uint32 _denominator, uint32 _elasticity) internal {
        // require the parameters have sane values:
        require(_denominator >= 1, "SystemConfig: denominator must be >= 1");
        require(_elasticity >= 1, "SystemConfig: elasticity must be >= 1");
        eip1559Denominator = _denominator;
        eip1559Elasticity = _elasticity;

        bytes memory data = abi.encode(uint256(_denominator) << 32 | uint64(_elasticity));
        emit ConfigUpdate(VERSION, UpdateType.EIP_1559_PARAMS, data);
    }

    function _setStartBlock() internal {
        if (Storage.getUint(START_BLOCK_SLOT) == 0) {
            Storage.setUint(START_BLOCK_SLOT, block.number);
        }
    }

    function resourceConfig()
        external
        view
        returns (IResourceMetering.ResourceConfig memory)
    {
        return _resourceConfig;
    }

    function _setResourceConfig(IResourceMetering.ResourceConfig memory _config)
        internal
    {
        // Min base fee must be less than or equal to max base fee.
        require(
            _config.minimumBaseFee <= _config.maximumBaseFee, "SystemConfig: min base fee must be less than max base"
        );
        // Base fee change denominator must be greater than 1.
        require(_config.baseFeeMaxChangeDenominator > 1, "SystemConfig: denominator must be larger than 1");
        // Max resource limit plus system tx gas must be less than or equal to the L2 gas limit.
        // The gas limit must be increased before these values can be increased.
        require(_config.maxResourceLimit + _config.systemTxMaxGas <= gasLimit, "SystemConfig: gas limit too low");
        // Elasticity multiplier must be greater than 0.
        require(_config.elasticityMultiplier > 0, "SystemConfig: elasticity multiplier cannot be 0");
        // No precision loss when computing target resource limit.
        require(
            ((_config.maxResourceLimit / _config.elasticityMultiplier) * _config.elasticityMultiplier)
                == _config.maxResourceLimit,
            "SystemConfig: precision loss with target resource limit"
        );

        _resourceConfig = _config;
    }
}
