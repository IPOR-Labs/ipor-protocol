// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import "./types/IporTypes.sol";

/// @title Interface for interaction with IporOracle, smart contract responsible for managing IPOR Index.
interface IIporOracle {
    /// @notice Structure representing parameters required to update an IPOR index for a given asset.
    /// @dev This structure is used in the `updateIndexes` method to provide necessary details for updating IPOR indexes.
    ///      For assets other than '_stEth', the 'quasiIbtPrice' field is not utilized in the update process.
    /// @param asset The address of the underlying asset/stablecoin supported by the IPOR Protocol.
    /// @param indexValue The new value of the IPOR index to be set for the specified asset.
    /// @param updateTimestamp The timestamp at which the index value is updated, used to calculate accrued interest.
    /// @param quasiIbtPrice The quasi interest-bearing token (IBT) price, applicable only for the '_stEth' asset.
    ///                      Represents a specialized value used in calculations for staked Ethereum.
    struct UpdateIndexParams {
        address asset;
        uint256 indexValue;
        uint256 updateTimestamp;
        uint256 quasiIbtPrice;
    }

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

    /// @notice Updates the Indexes based on the provided parameters.
    /// It is marked as 'onlyUpdater' meaning it has restricted access, and 'whenNotPaused' indicating it only operates when the contract is not paused.
    /// @param indexesToUpdate An array of `IIporOracle.UpdateIndexParams` to be updated.
    /// The structure typically contains fields like 'asset', 'indexValue', 'updateTimestamp', and 'quasiIbtPrice'.
    /// However, 'updateTimestamp' and 'quasiIbtPrice' are not used in this function.
    function updateIndexes(UpdateIndexParams[] calldata indexesToUpdate) external;

    /// @notice Updates both the Indexes and the Quasi IBT (Interest Bearing Token) Price based on the provided parameters.
    /// @param indexesToUpdate An array of `IIporOracle.UpdateIndexParams` to be updated.
    /// The structure contains fields such as 'asset', 'indexValue', 'updateTimestamp', and 'quasiIbtPrice', all of which are utilized in this update process.
    function updateIndexesAndQuasiIbtPrice(IIporOracle.UpdateIndexParams[] calldata indexesToUpdate) external;

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
