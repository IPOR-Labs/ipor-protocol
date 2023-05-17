// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IStrategy.sol";

/// @title Interface for interaction with Compound.
/// @notice It standarises the calls made by the asset management to the external DeFi protocol.
interface IStrategyCompound is IStrategy {
    /// @notice Emmited when blocks per day changed by Owner.
    /// @param changedBy account address that changed blocks per day
    /// @param oldBlocksPerDay old value blocks per day
    /// @param newBlocksPerDay new value blocks per day
    event BlocksPerDayChanged(
        address changedBy,
        uint256 oldBlocksPerDay,
        uint256 newBlocksPerDay
    );
}
