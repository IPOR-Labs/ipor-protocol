// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {StorageLibEthereum} from "../libraries/StorageLibEthereum.sol";

interface IAmmGovernanceServiceEthereum {
    function setMessageSigner(address messageSigner) external;

    function setAssetLensData(address asset, StorageLibEthereum.AssetLensDataValue memory assetLensData) external;

    function setAssetServices(address asset, StorageLibEthereum.AssetServicesValue memory assetServices) external;

    function setAmmGovernancePoolConfiguration(
        address asset,
        StorageLibEthereum.AssetGovernancePoolConfigValue calldata assetGovernancePoolConfig
    ) external;
}
