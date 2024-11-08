// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {StorageLibBaseV1} from "../libraries/StorageLibBaseV1.sol";

interface IAmmGovernanceServiceBaseV1 {
    function setMessageSigner(address messageSigner) external;

    function setAssetLensData(address asset, StorageLibBaseV1.AssetLensDataValue memory assetLensData) external;

    function setAssetServices(address asset, StorageLibBaseV1.AssetServicesValue memory assetServices) external;

    function setAmmGovernancePoolConfiguration(
        address asset,
        StorageLibBaseV1.AssetGovernancePoolConfigValue calldata assetGovernancePoolConfig
    ) external;
}
