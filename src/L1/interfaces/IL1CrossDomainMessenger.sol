// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICrossDomainMessenger } from "@redprint-core/universal/interfaces/ICrossDomainMessenger.sol";
import { ISuperchainConfig } from "@redprint-core/L1/interfaces/ISuperchainConfig.sol";
import { IOptimismPortal } from "@redprint-core/L1/interfaces/IOptimismPortal.sol";
import { ISystemConfig } from "@redprint-core/L1/interfaces/ISystemConfig.sol";

interface IL1CrossDomainMessenger is ICrossDomainMessenger {
    function PORTAL() external view returns (IOptimismPortal);
    function initialize(
        ISuperchainConfig _superchainConfig,
        IOptimismPortal _portal,
        ISystemConfig _systemConfig
    )
        external;
    function portal() external view returns (IOptimismPortal);
    function superchainConfig() external view returns (ISuperchainConfig);
    function systemConfig() external view returns (ISystemConfig);
    function version() external view returns (string memory);

    function __constructor__() external;
}