// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Structs used in IporOracle smart contract
library IporOracleTypes {
    /// @notice IPOR Index Structure of storage for a given asset
    struct IPOR {
        /// @notice Quasi Interest Bearing Token Price - it is a equation: quasiIbtPrice = oldQuasiIbtPrice + (Ipor Index * Delta Time)
        /// @dev `quasiIbtPrice` is an exponent of e (Euler's number) without division by number of seconds in a year,
        /// @dev is used to calculate ibtPrice as a continuous compounding interest: ibtPrice = initialIbtPrice * e^(quasiIbtPrice / SECONDS_IN_YEAR)
        uint128 quasiIbtPrice;
        /// @notice IPOR Index value.
        uint64 indexValue;
        /// @notice Timestamp of most recent IPOR index update, action performed by Oracle Service (refer to the documentation for more details)
        uint32 lastUpdateTimestamp;
    }
}
