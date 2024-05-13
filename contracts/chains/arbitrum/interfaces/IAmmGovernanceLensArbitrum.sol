// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";

interface IAmmGovernanceLensArbitrum {
    function getIporIndexOracle(address asset) external view returns (address);
    function getMessageSigner() external view returns (address);
    function getAssetLensData(address asset) external view returns (StorageLibArbitrum.AssetLensDataValue memory);
    function getAssetServices(address asset) external view returns (StorageLibArbitrum.AssetServicesValue memory);
}