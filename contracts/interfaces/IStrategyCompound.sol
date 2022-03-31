// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./IStrategy.sol";

/// @title Interface for interaction with Compound strategy which represent external DeFi protocol.
interface IStrategyCompound is IStrategy {
    /// @notice Emmited when blocks per year changed by Owner.
    /// @param changedBy account address who changed blocks per year
    /// @param oldBlocksPerYear old value blocks per year
    /// @param newBlocksPerYear new value blocks per year
    event BlocksPerYearChanged(
        address changedBy,
        uint256 oldBlocksPerYear,
        uint256 newBlocksPerYear
    );
}
