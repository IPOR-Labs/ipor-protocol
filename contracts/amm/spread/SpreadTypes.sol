// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;


library SpreadTypes {

    /// @notice structure used to save the weighted notional for the 28 days into storage
    /// weightedNotionalPayFixed without decimals - uint96 - bytes 0-96
    /// lastUpdateTimePayFixed - uint32 - bytes 96-128
    /// weightedNotionalReceiveFixed  without decimals - uint96 - bytes 128-224
    /// lastUpdateTimeReceiveFixed - uint32 - bytes 224-256
    struct WeightedNotional28DaysStorage {
        bytes32 weightedNotional;
    }

    /// @notice Dto for the last 28 days
    struct WeightedNotional28DaysMemory {
        /// @notice weightedNotionalPayFixed with 18 decimals
        uint256 weightedNotionalPayFixed;
        /// @notice lastUpdateTimePayFixed timestamp in seconds
        uint256 lastUpdateTimePayFixed;
        /// @notice weightedNotionalReceiveFixed with 18 decimals
        uint256 weightedNotionalReceiveFixed;
        /// @notice lastUpdateTimeReceiveFixed timestamp in seconds
        uint256 lastUpdateTimeReceiveFixed;
    }

}