// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DarcyDataProviderTypes {
    struct AssetConfig {
        address milton;
        address miltonStorage;
    }

    struct IporFront {
        //@notice Asset Symbol like USDT, USDC, DAI etc.
        string asset;
        //@notice IPOR Index Value
        uint256 indexValue;
        //@notice Interest Bearing Token Price
        uint256 ibtPrice;
        //@notice exponential moving average
        uint256 exponentialMovingAverage;
        uint256 exponentialWeightedMovingVariance;
        //@notice block timestamp
        uint256 blockTimestamp;
    }
}
