// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./IStrategy.sol";

/// @title Interface for interaction with Compound. 
/// @notice It standarises the calls made by the asset management to the external DeFi protocol.
interface IStrategyCompound is IStrategy {
    /// @notice Emmited when blocks per year changed by Owner.
    /// @param changedBy account address that changed blocks per year
    /// @param oldBlocksPerYear old value blocks per year
    /// @param newBlocksPerYear new value blocks per year
    event BlocksPerYearChanged(
        address changedBy,
        uint256 oldBlocksPerYear,
        uint256 newBlocksPerYear
    );
}
