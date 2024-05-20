// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {SpreadStorageLibsBaseV1} from "../spread/SpreadStorageLibsBaseV1.sol";

struct SpreadInputData {
    /// @notice Swap's balance for Pay Fixed leg
    uint256 totalCollateralPayFixed;
    /// @notice Swap's balance for Receive Fixed leg
    uint256 totalCollateralReceiveFixed;
    /// @notice Liquidity Pool's Balance
    uint256 liquidityPoolBalance;
    /// @notice Swap's notional
    uint256 swapNotional;
    /// @notice demand spread factor used in demand spread calculation, value without decimals
    uint256 demandSpreadFactor;
    /// @notice List of supported tenors in seconds
    uint256[] tenorsInSeconds;
    /// @notice List of storage ids for a TimeWeightedNotional for all tenors for a given asset

    SpreadStorageLibsBaseV1.StorageId[] timeWeightedNotionalStorageIds;
    /// @notice Storage id for a TimeWeightedNotional for a specific tenor and asset.
    SpreadStorageLibsBaseV1.StorageId timeWeightedNotionalStorageId;
    // @notice Calculation for tenor in seconds
    uint256 selectedTenorInSeconds;
}
