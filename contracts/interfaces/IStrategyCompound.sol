// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "contracts/interfaces/IStrategy.sol";

/// @title Interface for interacting with Compound.
/// @notice It standarises the calls made by the asset management to the external DeFi protocol.
interface IStrategyCompound is IStrategy {
    /// @notice Emitted when blocks per day changed by Owner.
    /// @param newBlocksPerDay new value blocks per day
    event BlocksPerDayChanged(uint256 newBlocksPerDay);
}
