// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/AmmMath.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from "../libraries/AmmMath.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import {Errors} from "../Errors.sol";

contract MiltonSpreadModel is IMiltonSpreadModel {
    IIporConfiguration internal _iporConfiguration;

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration) external {
        _iporConfiguration = initialIporConfiguration;
    }

    function calculateSpread(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        return
            IMiltonStorage(_iporConfiguration.getMiltonStorage())
                .calculateSpread(asset, calculateTimestamp);
    }

    function calculateAtParComponentPayFixed(
        address asset,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kVol = iporAssetConfiguration
            .getSpreadAtParComponentKVolValue();

        uint256 kHist = iporAssetConfiguration
            .getSpreadAtParComponentKHistValue();

        uint256 maxSpreadValue = iporAssetConfiguration.getSpreadMaxValue();

        if (exponentialWeightedMovingVariance == Constants.D18) {
            return maxSpreadValue;
        } else {
            uint256 historicalDeviation = _calculateHistoricalDeviationPayFixed(
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
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kVol = iporAssetConfiguration
            .getSpreadAtParComponentKVolValue();

        uint256 kHist = iporAssetConfiguration
            .getSpreadAtParComponentKHistValue();

        uint256 maxSpreadValue = iporAssetConfiguration.getSpreadMaxValue();

        if (exponentialWeightedMovingVariance == Constants.D18) {
            return maxSpreadValue;
        } else {
            uint256 historicalDeviation = _calculateHistoricalDeviationRecFixed(
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

    function _calculateHistoricalDeviationPayFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage < iporIndexValue) {
            return 0;
        } else {
            uint256 mu = AmmMath.absoluteValue(
                int256(exponentialMovingAverage) - int256(iporIndexValue)
            );
            if (mu == Constants.D18) {
                return maxSpreadValue;
            } else {
                return
                    AmmMath.division(kHist * Constants.D18, Constants.D18 - mu);
            }
        }
    }

    function _calculateHistoricalDeviationRecFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage > iporIndexValue) {
            return 0;
        } else {
            uint256 mu = AmmMath.absoluteValue(
                int256(exponentialMovingAverage) - int256(iporIndexValue)
            );
            if (mu == Constants.D18) {
                return maxSpreadValue;
            } else {
                return
                    AmmMath.division(kHist * Constants.D18, Constants.D18 - mu);
            }
        }
    }

    function _calculateAtParComponentVolatility(
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
        uint256 recFixedDerivativesBalance,
        int256 soapPayFixed
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kf = iporAssetConfiguration.getSpreadDemandComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadDemandComponentLambdaValue();

        uint256 kOmega = iporAssetConfiguration
            .getSpreadDemandComponentKOmegaValue();

        uint256 maxLiquidityRedemptionValue = iporAssetConfiguration
            .getSpreadDemandComponentMaxLiquidityRedemptionValue();

        uint256 maxSpreadValue = iporAssetConfiguration.getSpreadMaxValue();

        uint256 kfDenominator = maxLiquidityRedemptionValue -
            _calculatePayFixedAdjustedUtilizationRate(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                lambda
            );

        if (kfDenominator > 0) {
            uint256 kOmegaDenominator = Constants.D18 -
                _calculateSoapPlus(soapPayFixed, payFixedDerivativesBalance);
            if (kOmegaDenominator > 0) {
                return
                    AmmMath.division(kf * Constants.D18, kfDenominator) +
                    AmmMath.division(kOmega * Constants.D18, kOmegaDenominator);
            } else {
                return maxSpreadValue;
            }
        } else {
            return maxSpreadValue;
        }
    }

    function calculateDemandComponentRecFixed(
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapRecFixed
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kf = iporAssetConfiguration.getSpreadDemandComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadDemandComponentKOmegaValue();

        uint256 kOmega = iporAssetConfiguration
            .getSpreadDemandComponentKOmegaValue();

        uint256 maxLiquidityRedemptionValue = iporAssetConfiguration
            .getSpreadDemandComponentMaxLiquidityRedemptionValue();

        uint256 maxSpreadValue = iporAssetConfiguration.getSpreadMaxValue();

        uint256 kfDenominator = maxLiquidityRedemptionValue -
            _calculateRecFixedAdjustedUtilizationRate(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                lambda
            );

        if (kfDenominator > 0) {
			uint256 kOmegaDenominator = Constants.D18 -
			_calculateSoapPlus(
				soapRecFixed,
				recFixedDerivativesBalance
			);
			if (kOmegaDenominator > 0) {
				return
                AmmMath.division(kf * Constants.D18, kfDenominator) +
                AmmMath.division(
                    kOmega * Constants.D18,
                    kOmegaDenominator
                );
			} else {
				return maxSpreadValue;
			}
            
        } else {
            return maxSpreadValue;
        }
    }

    function _calculateSoapPlus(int256 soap, uint256 derivativesBalance)
        internal
        pure
        returns (uint256)
    {
        if (soap > 0) {
            return
                AmmMath.division(
                    uint256(soap) * Constants.D18,
                    derivativesBalance
                );
        } else {
            return 0;
        }
    }

    //URlambda_leg(M0)
    function _calculatePayFixedAdjustedUtilizationRate(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRateRecFixed = _calculateUtilizationRateWithoutPosition(
                derivativeOpeningFee,
                liquidityPool,
                recFixedDerivativesBalance
            );

        uint256 utilizationRatePayFixedWithPosition = _calculateUtilizationRateWithPosition(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance
            );

        uint256 adjustedUtilizationRate = _calculateImbalanceFactorWithLambda(
            utilizationRatePayFixedWithPosition,
            utilizationRateRecFixed,
            lambda
        );

        return adjustedUtilizationRate;
    }

    function _calculateRecFixedAdjustedUtilizationRate(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRatePayFixed = _calculateUtilizationRateWithoutPosition(
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance
            );

        uint256 utilizationRateRecFixedWithPosition = _calculateUtilizationRateWithPosition(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                recFixedDerivativesBalance
            );
        uint256 adjustedUtilizationRate = _calculateImbalanceFactorWithLambda(
            utilizationRateRecFixedWithPosition,
            utilizationRatePayFixed,
            lambda
        );
        return adjustedUtilizationRate;
    }

    event LogDebug(string name, uint256 value);

    function _calculateImbalanceFactorWithLambda(
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
    function _calculateUtilizationRateWithPosition(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                (derivativesBalance + derivativeDeposit) * Constants.D18,
                liquidityPoolBalance + derivativeOpeningFee
            );
    }

    //URleg(0)
    function _calculateUtilizationRateWithoutPosition(
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                derivativesBalance * Constants.D18,
                liquidityPoolBalance + derivativeOpeningFee
            );
    }
}
