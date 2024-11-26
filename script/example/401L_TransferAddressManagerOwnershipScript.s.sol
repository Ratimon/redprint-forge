// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "@redprint-forge-std/Script.sol";
import {console} from "@redprint-forge-std/console.sol";
import {Vm, VmSafe} from "@redprint-forge-std/Vm.sol";
import {IDeployer, getDeployer} from "@redprint-deploy/deployer/DeployScript.sol";

import {AddressManager} from "@redprint-core/legacy/AddressManager.sol";


contract TransferAddressManagerOwnershipScript is Script {

    IDeployer deployerProcedue;


    function run() public {

        deployerProcedue = getDeployer();
        deployerProcedue.setAutoSave(true);

        console.log("Transferring AddressManager ownership to ProxyAdmin");
        AddressManager addressManager = AddressManager(deployerProcedue.mustGetAddress("AddressManager"));
        address owner = addressManager.owner();
        address proxyAdmin = deployerProcedue.mustGetAddress("ProxyAdmin");
        (VmSafe.CallerMode mode ,address msgSender, ) = vm.readCallers();

        if (owner != proxyAdmin) {

            if(mode != VmSafe.CallerMode.Broadcast && msgSender != owner) {
                console.log("Pranking owner ...");
                vm.prank(owner);
             } else {
                console.log("Broadcasting ...");
                vm.broadcast(owner);
             }

            addressManager.transferOwnership(proxyAdmin);
            console.log("AddressManager ownership transferred to %s", proxyAdmin);
        }

        require(addressManager.owner() == proxyAdmin);

    }

}
