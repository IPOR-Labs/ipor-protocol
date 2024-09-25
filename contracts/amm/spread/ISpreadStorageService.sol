// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../../amm/spread/SpreadTypes.sol";

/// @title Spread interface for storage lens
interface ISpreadStorageService {
    /// @notice Updates the time-weighted notional values for multiple assets and tenors.
    /// @dev This function can only be called by the contract owner and overrides any existing implementation.
    ///     It iterates through an array of `TimeWeightedNotionalMemory` structures, checks each one for validity,
    ///     and then saves the updated time-weighted notional values.
    /// @param timeWeightedNotionalMemories An array of `TimeWeightedNotionalMemory` structures, where each structure
    ///        contains information about the asset, tenor, and the new time-weighted notional value to be updated.
    ///        Each `TimeWeightedNotionalMemory` structure should have a `storageId` identifying the asset and tenor
    ///        combination, along with the notional values and other relevant information.
    /// @notice The function employs an `unchecked` block for the loop iteration to optimize gas usage, assuming that
    ///         the arithmetic operation will not overflow under normal operation conditions.
    function updateTimeWeightedNotional(
        SpreadTypes.TimeWeightedNotionalMemory[] calldata timeWeightedNotionalMemories
    ) external;
}
