// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployScript} from "@redprint-deploy/deployer/DeployScript.sol";
import {DeployerFunctions, IDeployer} from "@redprint-deploy/deployer/DeployerFunctions.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {IAddressManager} from "@redprint-core/legacy/interfaces/IAddressManager.sol";
import {AddressManager} from "@redprint-core/legacy/AddressManager.sol";
import {ProxyAdmin} from "@redprint-core/universal/ProxyAdmin.sol";

/// @custom:security-contact Consult full internal deploy script at https://github.com/Ratimon/redprint-forge
contract DeployAndSetupProxyAdminScript is DeployScript {
    using DeployerFunctions for IDeployer ;
    ProxyAdmin proxyAdmin;
    string mnemonic = vm.envString("MNEMONIC");
    uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1);
    address owner = vm.envOr("DEPLOYER_ADDRESS", vm.addr(ownerPrivateKey));

    function deploy() external returns (ProxyAdmin) {
        proxyAdmin = deployer.deploy_ProxyAdmin("ProxyAdmin", address(owner));
        require(proxyAdmin.owner() == address(owner));
        return proxyAdmin;
    }

    function initialize() external {
        AddressManager addressManager = AddressManager(deployer.mustGetAddress("AddressManager"));
        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();
        if ( address(proxyAdmin.addressManager()) != address(addressManager)) {
             if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
                console.log("Pranking ower ...");
                vm.prank(owner);
             } else {
                console.log("Broadcasting ...");
                vm.broadcast(owner);
             }
            proxyAdmin.setAddressManager( IAddressManager(address(addressManager)));
            console.log("AddressManager setted to : %s", address(addressManager));
        }
        address safe = deployer.mustGetAddress("SystemOwnerSafe");
        if (proxyAdmin.owner() != safe) {
            if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
                console.log("Pranking ower ...");
                vm.prank(owner);
             } else {
                console.log("Broadcasting ...");
                vm.broadcast(owner);
             }

            proxyAdmin.transferOwnership(safe);
            console.log("ProxyAdmin ownership transferred to Safe at: %s", safe);
        }
    }
}
