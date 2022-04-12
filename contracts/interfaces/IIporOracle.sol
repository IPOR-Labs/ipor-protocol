// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "./types/IporTypes.sol";

/// @title Interface for interaction with IporOracle, smart contract responsible for managing IPOR Index.
interface IIporOracle {
    /// @notice Returns current version of IporOracle's
    /// @return current IporOracle version
    function getVersion() external pure returns (uint256);

    /// @notice Gets IPOR Index indicators for a given asset
    /// @dev all returned values represented in 18 decimals
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return value IPOR Index value for a given asset
    /// @return ibtPrice Interest Bearing Token Price for a given IPOR Index
    /// @return exponentialMovingAverage Exponential moving average for a given IPOR Index
    /// @return exponentialWeightedMovingVariance Exponential weighted movien variance for a given IPOR Index
    /// @return lastUpdateTimestamp Last IPOR Index update done by Charlie off-chain service
    function getIndex(address asset)
        external
        view
        returns (
            uint256 value,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 lastUpdateTimestamp
        );

    /// @notice Gets accrued IPOR Index indicators for a given timestamp and asset .
    /// @param calculateTimestamp time of accrued IPOR Index calculation
    /// @param asset underlying / stablecoin address supported by IPOR Protocol.
    /// @return accruedIpor structure {IporTypes.AccruedIpor}
    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
        view
        returns (IporTypes.AccruedIpor memory accruedIpor);

    /// @notice Calculates accrued Interest Bearing Token price for a given asset and timestamp.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol.
    /// @param calculateTimestamp time of accrued Interest Bearing Token price calculation
    /// @return accrued IBT price, represented in 18 decimals
    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        returns (uint256);

    /// @notice Updates IPOR Index for a given asset. Function available only for Updater
    /// @dev Emmits {IporIndexUpdate} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param indexValue new IPOR Index value represented in 18 decimals
    function updateIndex(address asset, uint256 indexValue) external;

    /// @notice Updates IPOR indexes for a given assets. Function available only for Updater
    /// @dev Emmits {IporIndexUpdate} event.
    /// @param assets underlying / stablecoin addresses supported by IPOR Protocol
    /// @param indexValues new IPOR Index values
    function updateIndexes(address[] memory assets, uint256[] memory indexValues) external;

    /// @notice Adds new Updater. Updater has right to update IPOR Index. Function available only for Owner.
    /// @param newUpdater new updater address
    function addUpdater(address newUpdater) external;

    /// @notice Removes Updater. Function available only for Owner.
    /// @param updater updater address
    function removeUpdater(address updater) external;

    /// @notice Checks if given account is an Updater.
    /// @param account account for checking
    /// @return 0 if account is not updater, 1 if account is updater.
    function isUpdater(address account) external view returns (uint256);

    /// @notice Adds new asset which IPOR Protocol will support. Function available only for Owner.
    /// @param newAsset new asset address.
    function addAsset(address newAsset) external;

    /// @notice Removes asset which IPOR Protocol will not support. Function available only for Owner.
    /// @param asset  underlying / stablecoin address which currenlty is supported by IPOR Protocol.
    function removeAsset(address asset) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from IporOracle.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from IporOracle.
    function unpause() external;

    /// @notice Emmited when Charlie update IPOR Index.
    /// @param asset underlying / stablecoin address
    /// @param indexValue IPOR Index value represented in 18 decimals
    /// @param quasiIbtPrice quasi Interest Bearing Token price represented in 18 decimals.
    /// @param exponentialMovingAverage Exponential Moving Average represented in 18 decimals.
    /// @param exponentialWeightedMovingVariance Exponential Weighted Moving Variance
    /// @param updateTimestamp moment when IPOR Index was updated.
    event IporIndexUpdate(
        address asset,
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance,
        uint256 updateTimestamp
    );

    /// @notice event emitted when IPOR Index Updater is added by Owner
    /// @param newUpdater new Updater address
    event IporIndexAddUpdater(address newUpdater);

    /// @notice event emitted when IPOR Index Updater is removed by Owner
    /// @param updater updater address
    event IporIndexRemoveUpdater(address updater);

    /// @notice event emitted when new asset is added by Owner to list of assets supported in IPOR Protocol.
    /// @param newAsset new asset address
    event IporIndexAddAsset(address newAsset);

    /// @notice event emitted when asset is removed by Owner from list of assets supported in IPOR Protocol.
    /// @param asset asset address
    event IporIndexRemoveAsset(address asset);
}
