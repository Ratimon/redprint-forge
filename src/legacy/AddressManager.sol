// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {Ownable} from "@redprint-openzeppelin/access/Ownable.sol";

/// @custom:security-contact Consult full code at https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/src/legacy/AddressManager.sol
contract AddressManager is Ownable {
    mapping(bytes32 => address) private addresses;
    event AddressSet(string indexed name, address newAddress, address oldAddress);

    function setAddress(string memory _name, address _address) external onlyOwner {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;
        emit AddressSet(_name, _address, oldAddress);
    }

    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}
