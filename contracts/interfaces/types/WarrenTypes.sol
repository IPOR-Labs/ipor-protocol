// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library WarrenTypes {
    //@notice IPOR Structure
    struct IPOR {
        //@notice block timestamp
        uint32 blockTimestamp;
        //@notice IPOR Index Value shown as WAD
        uint128 indexValue;
        //@notice quasi Interest Bearing Token Price, it is IBT Price without division by year in seconds, shown as WAD
        uint128 quasiIbtPrice;
        //@notice exponential moving average - required for calculating SPREAD in Milton, shown as WAD
        uint128 exponentialMovingAverage;
        //@notice exponential weighted moving variance - required for calculating SPREAD in Milton, shown as WAD
        uint128 exponentialWeightedMovingVariance;
    }
}
