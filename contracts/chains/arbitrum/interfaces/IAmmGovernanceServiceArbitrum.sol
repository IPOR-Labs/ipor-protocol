// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";

interface IAmmGovernanceServiceArbitrum {
    function setIporIndexOracle(address asset, address iporIndexOracle) external;
    function setMessageSigner(address messageSigner) external;
    function setAssetLensData(address asset, StorageLibArbitrum.AssetLensDataValue memory assetLensData) external;
    function setAssetServices(address asset, StorageLibArbitrum.AssetServicesValue memory assetServices) external;
    function setAmmGovernancePoolConfiguration(
        address asset,
        StorageLibArbitrum.AssetGovernancePoolConfigValue calldata assetGovernancePoolConfig
    ) external;
}