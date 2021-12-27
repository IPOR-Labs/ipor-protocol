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
		
		uint256 maxSpreadValue = iporAssetConfiguration.getSpreadMaxValue();

		if (exponentialWeightedMovingVariance == Constants.D18) {
			return maxSpreadValue;
		} else {
			uint256 historicalDeviation = calculateHistoricalDeviationPayFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage,
				maxSpreadValue
            );
			if (historicalDeviation >= maxSpreadValue) {
				return maxSpreadValue;
			} else {
				return
				AmmMath.division(
					kVol * Constants.D18,
					Constants.D18 - exponentialWeightedMovingVariance
				) + historicalDeviation;
			}
			
		}

        
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

		uint256 maxSpreadValue = iporAssetConfiguration.getSpreadMaxValue();

		if (exponentialWeightedMovingVariance == Constants.D18) {
			return maxSpreadValue;
		} else {
			uint256 historicalDeviation = calculateHistoricalDeviationRecFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage,
				maxSpreadValue
            );
			if (historicalDeviation >= maxSpreadValue) {
				return maxSpreadValue;
			} else {
				return
				AmmMath.division(
					kVol * Constants.D18,
					Constants.D18 - exponentialWeightedMovingVariance
				) + historicalDeviation;
			}
			
		}
        
    }

    function calculateHistoricalDeviationPayFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
		uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage < iporIndexValue) {
            return 0;
        } else {
			uint256 mu = AmmMath.absoluteValue(
				int256(exponentialMovingAverage) -
					int256(iporIndexValue)
			);
			if (mu == Constants.D18) {
				return maxSpreadValue;
			} else {
				return
                AmmMath.division(
                    kHist * Constants.D18,
                    Constants.D18 - mu
                );
			}
            
        }
    }

    function calculateHistoricalDeviationRecFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
		uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage > iporIndexValue) {
            return 0;
        } else {
			uint256 mu = AmmMath.absoluteValue(
				int256(exponentialMovingAverage) -
					int256(iporIndexValue)
			);
			if (mu == Constants.D18) {
				return maxSpreadValue;
			} else {
				return
                AmmMath.division(
                    kHist * Constants.D18,
                    Constants.D18 - mu
                );
			}            
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
            .getSpreadDemandComponentKfValue();

        uint256 kOmega = iporAssetConfiguration
            .getSpreadDemandComponentKOmegaValue();

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
                        kOmega
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
            .getSpreadDemandComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadDemandComponentKOmegaValue();

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
        uint256 kOmega
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
            calculateImbalanceFactorWithKOmega(
                utilizationRatePayFixedWithPosition,
                utilizationRateRecFixed,
                kOmega
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
        uint256 adjustedUtilizationRate = calculateImbalanceFactorWithKOmega(
            utilizationRateRecFixedWithPosition,
            utilizationRatePayFixed,
            lambda
        );

        return adjustedUtilizationRate;
    }

    function calculateImbalanceFactorWithKOmega(
        uint256 utilizationRateLegWithPosition,
        uint256 utilizationRateLegWithoutPosition,
        uint256 kOmega
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
                        kOmega *
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
