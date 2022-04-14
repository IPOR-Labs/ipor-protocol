// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

/// @title Structs used in IporOracle smart contract
library IporOracleTypes {
    //@notice IPOR Index Structure for a given asset
    struct IPOR {
        //@notice Tiestamp of most recent IPOR index update, action performed by Charlie (refer to the documentation for more details)
        uint32 lastUpdateTimestamp;
        //@notice IPOR Index value.
        uint128 indexValue;
        //@notice Quasi Interest Bearing Token Price - IBT Price without division by year in seconds
        uint128 quasiIbtPrice;
        /// @notice Exponential Moving Average
        /// @dev used in calculating spread in MiltonSpreadModel smart contract
        uint128 exponentialMovingAverage;
        //@notice exponential weighted moving variance - required for calculating spread in Milton
        uint128 exponentialWeightedMovingVariance;
    }
}
