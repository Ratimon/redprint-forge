// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@redprint-openzeppelin/access/Ownable.sol";
import {Constants} from "@redprint-core/libraries/Constants.sol";
import {IAddressManager} from "@redprint-core/legacy/interfaces/IAddressManager.sol";
import {IL1ChugSplashProxy, IStaticL1ChugSplashProxy} from "@redprint-core/legacy/interfaces/IL1ChugSplashProxy.sol";
import {IStaticERC1967Proxy} from "@redprint-core/universal/interfaces/IStaticERC1967Proxy.sol";
import {IProxy} from "@redprint-core/universal/interfaces/IProxy.sol";

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/universal/ProxyAdmin.sol
contract ProxyAdmin is Ownable {
    enum ProxyType {
        ERC1967,
        CHUGSPLASH,
        RESOLVED
    }
     /// @notice A mapping of proxy types, used for backwards compatibility.
    mapping(address => ProxyType) public proxyType;
    /// @notice A reverse mapping of addresses to names held in the AddressManager. This must be
    ///         manually kept up to date with changes in the AddressManager for this contract
    ///         to be able to work as an admin for the ResolvedDelegateProxy type.
    mapping(address => string) public implementationName;
    /// @notice The address of the address manager, this is required to manage the
    ///         ResolvedDelegateProxy type.
    IAddressManager public addressManager;
    bool internal upgrading;

    constructor(address _owner) Ownable() {
        _transferOwnership(_owner);
    }

    function setProxyType(address _address, ProxyType _type) external onlyOwner {
        proxyType[_address] = _type;
    }

    function setImplementationName(address _address, string memory _name)
        external
        onlyOwner
    {
        implementationName[_address] = _name;
    }

    function setAddressManager(IAddressManager _address) external onlyOwner {
        addressManager = _address;
    }

    function setAddress(string memory _name, address _address) external onlyOwner {
        addressManager.setAddress(_name, _address);
    }

    function setUpgrading(bool _upgrading) external onlyOwner {
        upgrading = _upgrading;
    }

    function isUpgrading() external view returns (bool) {
        return upgrading;
    }

    function getProxyImplementation(address _proxy)
        external
        view
        returns (address)
    {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            return IStaticERC1967Proxy(_proxy).implementation();
        } else if (ptype == ProxyType.CHUGSPLASH) {
            return IStaticL1ChugSplashProxy(_proxy).getImplementation();
        } else if (ptype == ProxyType.RESOLVED) {
            return addressManager.getAddress(implementationName[_proxy]);
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }
    }

    function getProxyAdmin(address payable _proxy)
        external
        view
        returns (address)
    {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            return IStaticERC1967Proxy(_proxy).admin();
        } else if (ptype == ProxyType.CHUGSPLASH) {
            return IStaticL1ChugSplashProxy(_proxy).getOwner();
        } else if (ptype == ProxyType.RESOLVED) {
            return addressManager.owner();
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }
    }

    function changeProxyAdmin(address payable _proxy, address _newAdmin)
        external
        onlyOwner
    {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            IProxy(_proxy).changeAdmin(_newAdmin);
        } else if (ptype == ProxyType.CHUGSPLASH) {
            IL1ChugSplashProxy(_proxy).setOwner(_newAdmin);
        } else if (ptype == ProxyType.RESOLVED) {
            addressManager.transferOwnership(_newAdmin);
        } else {
            revert("ProxyAdmin: unknown proxy type");
        }
    }

    function upgrade(address payable _proxy, address _implementation)
        public
        onlyOwner
    {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            IProxy(_proxy).upgradeTo(_implementation);
        } else if (ptype == ProxyType.CHUGSPLASH) {
            IL1ChugSplashProxy(_proxy).setStorage(
                Constants.PROXY_IMPLEMENTATION_ADDRESS, bytes32(uint256(uint160(_implementation)))
            );
        } else if (ptype == ProxyType.RESOLVED) {
            string memory name = implementationName[_proxy];
            addressManager.setAddress(name, _implementation);
        } else {
            // It should not be possible to retrieve a ProxyType value which is not matched by
            // one of the previous conditions.
            assert(false);
        }
    }

    function upgradeAndCall(address payable _proxy, address _implementation, bytes memory _data)
        external payable
        onlyOwner
    {
        ProxyType ptype = proxyType[_proxy];
        if (ptype == ProxyType.ERC1967) {
            IProxy(_proxy).upgradeToAndCall{ value: msg.value }(_implementation, _data);
        } else {
            // reverts if proxy type is unknown
            upgrade(_proxy, _implementation);
            (bool success,) = _proxy.call{ value: msg.value }(_data);
            require(success, "ProxyAdmin: call to proxy after upgrade failed");
        }
    }
}
