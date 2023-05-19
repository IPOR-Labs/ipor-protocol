// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Structs used in comunication ItfDataProvider with Itf Application
library ItfDataProviderTypes {

    struct ItfIporOracleData {
        uint256 indexValue;
        uint256 ibtPrice;
        uint256 lastUpdateTimestamp;
        uint256 accruedIndexValue;
        uint256 accruedIbtPrice;
        uint256 accruedExponentialMovingAverage;
        uint256 accruedExponentialWeightedMovingVariance;
    }

    struct ItfMiltonStorageData {
        uint256 totalCollateralPayFixed;
        uint256 totalCollateralReceiveFixed;
        uint256 liquidityPool;
        uint256 vault;
        uint256 iporPublicationFee;
        uint256 treasury;
        uint256 totalNotionalPayFixed;
        uint256 totalNotionalReceiveFixed;
    }

    struct ItfAmmData {
        uint256 blockNumber;
        uint256 timestamp;
        address asset;
        ItfIporOracleData itfIporOracleData;
        ItfMiltonStorageData itfMiltonStorageData;
    }
}
