// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {StorageLibEthereum} from "../libraries/StorageLibEthereum.sol";

interface IAmmGovernanceLensEthereum {
    function getMessageSigner() external view returns (address);

    function getAssetLensData(address asset) external view returns (StorageLibEthereum.AssetLensDataValue memory);

    function getAssetServices(address asset) external view returns (StorageLibEthereum.AssetServicesValue memory);
}
