// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/IporTypes.sol";

/// @title Interface for interaction with IporOracle, smart contract responsible for managing IPOR Index.
interface IIporOracle {
    /// @notice Returns current version of IporOracle's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IporOracle version
    function getVersion() external pure returns (uint256);

    /// @notice Gets IPOR Index indicators for a given asset
    /// @dev all returned values represented in 18 decimals
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return indexValue IPOR Index value for a given asset calculated for time lastUpdateTimestamp
    /// @return ibtPrice Interest Bearing Token Price for a given IPOR Index calculated for time lastUpdateTimestamp
    /// @return lastUpdateTimestamp Last IPOR Index update done by off-chain service
    /// @dev For calculation accrued IPOR Index indicators (indexValue and ibtPrice) for a specified timestamp use {getAccruedIndex} function.
    /// Method {getIndex} calculates IPOR Index indicators for a moment when last update was done by off-chain service,
    /// this timestamp is stored in lastUpdateTimestamp variable.
    function getIndex(
        address asset
    ) external view returns (uint256 indexValue, uint256 ibtPrice, uint256 lastUpdateTimestamp);

    /// @notice Gets accrued IPOR Index indicators for a given timestamp and asset.
    /// @param calculateTimestamp time of accrued IPOR Index calculation
    /// @param asset underlying / stablecoin address supported by IPOR Protocol.
    /// @return accruedIpor structure {IporTypes.AccruedIpor}
    /// @dev ibtPrice included in accruedIpor structure is calculated using continuous compounding interest formula
    function getAccruedIndex(
        uint256 calculateTimestamp,
        address asset
    ) external view returns (IporTypes.AccruedIpor memory accruedIpor);

    /// @notice Calculates accrued Interest Bearing Token price for a given asset and timestamp.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol.
    /// @param calculateTimestamp time of accrued Interest Bearing Token price calculation
    /// @return accrued IBT price, represented in 18 decimals
    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp) external view returns (uint256);

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

    /// @notice Updates the IPOR index and quasi IBT (Interest Bearing Token) price for a specific asset.
    /// @dev This function can only be called by an authorized updater and when the contract is not paused.
    ///         It performs several checks to ensure the integrity of the update, such as asset support verification
    ///         and timestamp validation. If any of these checks fail, the function reverts with an appropriate error message.
    /// @param asset The address of the underlying asset for which the index and quasi IBT price are being updated.
    /// @param indexValue The new value of the IPOR index for the specified asset.
    /// @param updateTimestamp The timestamp at which the index value is updated.
    ///         This value must be greater than the last update timestamp and less than the current block timestamp.
    /// @param newQuasiIbtPrice The new quasi IBT price for the specified asset. For more information, see IporOracleTypes.IPOR.
    /// @custom:modifier onlyUpdater Restricts the function to be callable only by an authorized updater.
    /// @custom:modifier whenNotPaused Ensures the function is executed only when the contract is not paused.
    /// @custom:modifier whenAssetStEth Ensures that the asset is accepted and specific conditions (if any) for the asset are met.
    ///         The modifier whenAssetStEth is assumed to be a custom modifier specific to the asset type, in this case, possibly stETH.
    /// @custom:error IporOracleErrors.UpdateIndex This error is thrown if the asset is not supported or if the update timestamp is invalid.
    function updateIndexAndQuasiIbtPrice(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp,
        uint256 newQuasiIbtPrice
    ) external;

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
    /// @param newAsset new asset address
    /// @param updateTimestamp Time when start to accrue interest for Interest Bearing Token price.
    function addAsset(address newAsset, uint256 updateTimestamp) external;

    /// @notice Removes asset which IPOR Protocol will not support. Function available only for Owner.
    /// @param asset  underlying / stablecoin address which current is supported by IPOR Protocol.
    function removeAsset(address asset) external;

    /// @notice Checks if given asset is supported by IPOR Protocol.
    /// @param asset underlying / stablecoin address
    function isAssetSupported(address asset) external view returns (bool);

    /// @notice Emmited when Charlie update IPOR Index.
    /// @param asset underlying / stablecoin address
    /// @param indexValue IPOR Index value represented in 18 decimals
    /// @param quasiIbtPrice quasi Interest Bearing Token price represented in 18 decimals.
    /// @param updateTimestamp moment when IPOR Index was updated.
    event IporIndexUpdate(address asset, uint256 indexValue, uint256 quasiIbtPrice, uint256 updateTimestamp);

    /// @notice event emitted when IPOR Index Updater is added by Owner
    /// @param newUpdater new Updater address
    event IporIndexAddUpdater(address newUpdater);

    /// @notice event emitted when IPOR Index Updater is removed by Owner
    /// @param updater updater address
    event IporIndexRemoveUpdater(address updater);

    /// @notice event emitted when new asset is added by Owner to list of assets supported in IPOR Protocol.
    /// @param newAsset new asset address
    /// @param updateTimestamp update timestamp
    event IporIndexAddAsset(address newAsset, uint256 updateTimestamp);

    /// @notice event emitted when asset is removed by Owner from list of assets supported in IPOR Protocol.
    /// @param asset asset address
    event IporIndexRemoveAsset(address asset);
}
