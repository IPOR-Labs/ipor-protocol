// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {StorageLibBaseV1} from "../libraries/StorageLibBaseV1.sol";

interface IAmmGovernanceLensBaseV1 {
    function getMessageSigner() external view returns (address);

    function getAssetLensData(address asset) external view returns (StorageLibBaseV1.AssetLensDataValue memory);

    function getAssetServices(address asset) external view returns (StorageLibBaseV1.AssetServicesValue memory);
}
