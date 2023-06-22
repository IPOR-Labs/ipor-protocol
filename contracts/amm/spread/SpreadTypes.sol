// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@ipor-protocol/contracts/amm/spread/SpreadStorageLibs.sol";

library SpreadTypes {
    /// @notice structure used to save the weighted notional for the 28 days into storage
    /// timeWeightedNotionalPayFixed without decimals - uint96 - bytes 0-96
    /// lastUpdateTimePayFixed - uint32 - bytes 96-128
    /// timeWeightedNotionalReceiveFixed  without decimals - uint96 - bytes 128-224
    /// lastUpdateTimeReceiveFixed - uint32 - bytes 224-256
    struct WeightedNotionalStorage {
        bytes32 weightedNotional;
    }

    /// @notice Dto for the Weighted Notional
    struct TimeWeightedNotionalMemory {
        /// @notice timeWeightedNotionalPayFixed with 18 decimals
        uint256 timeWeightedNotionalPayFixed;
        /// @notice lastUpdateTimePayFixed timestamp in seconds
        uint256 lastUpdateTimePayFixed;
        /// @notice timeWeightedNotionalReceiveFixed with 18 decimals
        uint256 timeWeightedNotionalReceiveFixed;
        /// @notice lastUpdateTimeReceiveFixed timestamp in seconds
        uint256 lastUpdateTimeReceiveFixed;
        /// @notice storageId from SpreadStorageLibs
        SpreadStorageLibs.StorageId storageId;
    }

    struct TimeWeightedNotionalResponse {
        TimeWeightedNotionalMemory timeWeightedNotional;
        string key;
    }
}
