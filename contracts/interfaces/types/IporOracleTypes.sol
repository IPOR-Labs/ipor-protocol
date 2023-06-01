// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Structs used in IporOracle smart contract
library IporOracleTypes {
    //@notice IPOR Index Structure for a given asset
    struct IPOR {
        //@notice Quasi Interest Bearing Token Price - IBT Price without division by year in seconds
        uint128 quasiIbtPrice;
        //@notice IPOR Index value.
        uint64 indexValue;
        //@notice Tiestamp of most recent IPOR index update, action performed by Charlie (refer to the documentation for more details)
        uint32 lastUpdateTimestamp;
    }
}
