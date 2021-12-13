// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/AmmMath.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import { AmmMath } from "../libraries/AmmMath.sol";
import "../interfaces/IMiltonSpreadStrategy.sol";

contract MiltonSpreadStrategy is IMiltonSpreadStrategy {
    IIporConfiguration internal iporConfiguration;

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration) external {
        iporConfiguration = initialIporConfiguration;
    }

    function calculateSpread(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        return
            IMiltonStorage(iporConfiguration.getMiltonStorage())
                .calculateSpread(asset, calculateTimestamp);
    }

    function calculateAtParComponentPayFixed(
        address asset,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kVol = iporAssetConfiguration
            .getSpreadAtParComponentKVolValue();

        uint256 kHist = iporAssetConfiguration
            .getSpreadAtParComponentKHistValue();

        return
            AmmMath.division(
                kVol,
                Constants.D18 - exponentialWeightedMovingVariance
            ) +
            calculateHistoricalDeviationPayFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage
            );
    }

    function calculateAtParComponentRecFixed(
        address asset,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kVol = iporAssetConfiguration
            .getSpreadAtParComponentKVolValue();

        uint256 kHist = iporAssetConfiguration
            .getSpreadAtParComponentKHistValue();

        return
            AmmMath.division(
                kVol,
                Constants.D18 - exponentialWeightedMovingVariance
            ) +
            calculateHistoricalDeviationRecFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage
            );
    }

    function calculateHistoricalDeviationPayFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage < iporIndexValue) {
            return 0;
        } else {
            return
                AmmMath.division(
                    kHist,
                    Constants.D18 -
                        AmmMath.absoluteValue(
                            int256(exponentialMovingAverage) -
                                int256(iporIndexValue)
                        )
                );
        }
    }

    function calculateHistoricalDeviationRecFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage > iporIndexValue) {
            return 0;
        } else {
            return
                AmmMath.division(
                    kHist,
                    Constants.D18 -
                        AmmMath.absoluteValue(
                            int256(exponentialMovingAverage) -
                                int256(iporIndexValue)
                        )
                );
        }
    }

    function calculateAtParComponentVolatility(
        uint256 exponentialWeightedMovingVariance
    ) internal pure returns (uint256) {
        return AmmMath.sqrt(exponentialWeightedMovingVariance);
    }

    function calculateDemandComponentPayFixed(
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kf = iporAssetConfiguration
            .getSpreadUtilizationComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadUtilizationComponentLambdaValue();

        return
            AmmMath.division(
                kf * Constants.D18,
                Constants.D18 -
                    calculatePayFixedAdjustedUtilizationRate(
                        derivativeDeposit,
                        derivativeOpeningFee,
                        liquidityPool,
                        payFixedDerivativesBalance,
                        recFixedDerivativesBalance,
                        lambda
                    )
            );
    }

    function calculateDemandComponentRecFixed(
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kf = iporAssetConfiguration
            .getSpreadUtilizationComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadUtilizationComponentLambdaValue();

        return
            AmmMath.division(
                kf * Constants.D18,
                Constants.D18 -
                    calculateRecFixedAdjustedUtilizationRate(
                        derivativeDeposit,
                        derivativeOpeningFee,
                        liquidityPool,
                        payFixedDerivativesBalance,
                        recFixedDerivativesBalance,
                        lambda
                    )
            );
    }

    //URlambda_leg(M0)
    function calculatePayFixedAdjustedUtilizationRate(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRateRecFixed = calculateUtilizationRateWithoutPosition(
                derivativeOpeningFee,
                liquidityPool,
                recFixedDerivativesBalance
            );

        uint256 utilizationRatePayFixedWithPosition = calculateUtilizationRateWithPosition(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance
            );

        return
            calculateImbalanceFactorWithLambda(
                utilizationRatePayFixedWithPosition,
                utilizationRateRecFixed,
                lambda
            );
    }

    function calculateRecFixedAdjustedUtilizationRate(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRatePayFixed = calculateUtilizationRateWithoutPosition(
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance
            );

        uint256 utilizationRateRecFixedWithPosition = calculateUtilizationRateWithPosition(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                recFixedDerivativesBalance
            );
        uint256 adjustedUtilizationRate = calculateImbalanceFactorWithLambda(
            utilizationRateRecFixedWithPosition,
            utilizationRatePayFixed,
            lambda
        );

        return adjustedUtilizationRate;
    }

    function calculateImbalanceFactorWithLambda(
        uint256 utilizationRateLegWithPosition,
        uint256 utilizationRateLegWithoutPosition,
        uint256 lambda
    ) internal pure returns (uint256) {
        if (
            utilizationRateLegWithPosition >= utilizationRateLegWithoutPosition
        ) {
            return Constants.D18 - utilizationRateLegWithPosition;
        } else {
            return
                Constants.D18 -
                (utilizationRateLegWithPosition -
                    AmmMath.division(
                        lambda *
                            (utilizationRateLegWithoutPosition -
                                utilizationRateLegWithPosition),
                        Constants.D18
                    ));
        }
    }

    //@notice Calculates utilization rate including position which is opened
    function calculateUtilizationRateWithPosition(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance
    ) internal pure returns (uint256) {
        if ((liquidityPoolBalance + derivativeOpeningFee) != 0) {
            return
                AmmMath.division(
                    (derivativesBalance + derivativeDeposit) * Constants.D18,
                    liquidityPoolBalance + derivativeOpeningFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }

    //URleg(0)
    function calculateUtilizationRateWithoutPosition(
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance
    ) internal pure returns (uint256) {
        if (liquidityPoolBalance != 0) {
            return
                AmmMath.division(
                    derivativesBalance * Constants.D18,
                    liquidityPoolBalance + derivativeOpeningFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
