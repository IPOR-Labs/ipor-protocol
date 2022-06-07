// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

/// @title Structs used in comunication ItfDataProvider with Itf Application
library ItfDataProviderTypes {
    struct ItfMiltonData {
        uint256 maxSwapCollateralAmount;
        uint256 maxLpUtilizationRate;
        uint256 maxLpUtilizationPerLegRate;
        uint256 incomeFeeRate;
        uint256 openingFeeRate;
        uint256 openingFeeTreasuryPortionRate;
        uint256 iporPublicationFee;
        uint256 liquidationDepositAmount;
        uint256 wadLiquidationDepositAmount;
        uint256 maxLeverage;
        uint256 minLeverage;
        int256 spreadPayFixed;
        int256 spreadReceiveFixed;
        int256 soapPayFixed;
        int256 soapReceiveFixed;
        int256 soap;
    }

    struct ItfIporOracleData {
        uint256 decayFactorValue;
        uint256 indexValue;
        uint256 ibtPrice;
        uint256 exponentialMovingAverage;
        uint256 exponentialWeightedMovingVariance;
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

    struct ItfMiltonSpreadModelData {
        uint256 spreadPremiumsMaxValue;
        uint256 dCKfValue;
        uint256 dCLambdaValue;
        uint256 dCKOmegaValue;
        uint256 dCMaxLiquidityRedemptionValue;
        int256 payFixedRegionOneBase;
        int256 payFixedRegionOneSlopeForVolatility;
        int256 payFixedRegionOneSlopeForMeanReversion;
        int256 payFixedRegionTwoBase;
        int256 payFixedRegionTwoSlopeForVolatility;
        int256 payFixedRegionTwoSlopeForMeanReversion;
        int256 receiveFixedRegionOneBase;
        int256 receiveFixedRegionOneSlopeForVolatility;
        int256 receiveFixedRegionOneSlopeForMeanReversion;
        int256 receiveFixedRegionTwoBase;
        int256 receiveFixedRegionTwoSlopeForVolatility;
        int256 receiveFixedRegionTwoSlopeForMeanReversion;
    }

    struct ItfAmmData {
        ItfMiltonData itfMiltonData;
        ItfIporOracleData itfIporOracleData;
        ItfMiltonStorageData itfMiltonStorageData;
        ItfMiltonSpreadModelData itfMiltonSpreadModelData;
    }
}
