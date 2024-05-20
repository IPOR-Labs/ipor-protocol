// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../../amm/spread/SpreadStorageLibs.sol";

library SpreadTypes {

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

    /// @notice Technical structure used in Lens for the Weighted Notional params
    struct TimeWeightedNotionalResponse {
        /// @notice timeWeightedNotionalPayFixed time weighted notional params
        TimeWeightedNotionalMemory timeWeightedNotional;
        string key;
    }
}
