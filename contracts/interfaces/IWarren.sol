// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IWarren {
    function getVersion() external pure returns (uint256);

    function getIndex(address asset)
        external
        view
        returns (
            uint256 value,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 date
        );

    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
        view
        returns (DataTypes.AccruedIpor memory accruedIpor);

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        returns (uint256);

    function updateIndex(address asset, uint256 indexValue) external;

    function updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues
    ) external;

    function addUpdater(address updater) external;

    function removeUpdater(address updater) external;

    function isUpdater(address updater) external view returns (uint256);

    function addAsset(address asset) external;

    function removeAsset(address asset) external;

    function pause() external;

    function unpause() external;

    event IporIndexUpdate(
        address asset,
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 exponentialMovingAverage,
        uint256 newExponentialWeightedMovingVariance,
        uint256 date
    );

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexAddUpdater(address updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexRemoveUpdater(address updater);

    event IporIndexAddAsset(address newAsset);

    event IporIndexRemoveAsset(address newAsset);
}
