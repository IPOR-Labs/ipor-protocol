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
import "./MiltonSpreadModelCore.sol";
import "../configuration/MiltonSpreadConfiguration.sol";

contract MiltonSpreadModel is
    MiltonSpreadModelCore,
    MiltonSpreadConfiguration,
    IMiltonSpreadModel
{
    IIporConfiguration internal _iporConfiguration;

	constructor(address asset, address iporConfiguration) MiltonSpreadConfiguration(asset){		
		_iporConfiguration = IIporConfiguration(iporConfiguration);
	}
	

    function calculateSpread(
        uint256 calculateTimestamp,
        address asset,
        uint8 derivativeDirection,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee
    )
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {}

    function calculateSpreadPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soap
    ) external view override returns (uint256 spreadValue) {
        spreadValue =
            _calculateDemandComponentPayFixed(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soap
            ) +
            _calculateAtParComponentPayFixed(
                iporIndexValue,
                exponentialMovingAverage,
                exponentialWeightedMovingVariance
            );
    }

    function calculateSpreadRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soap
    ) external view override returns (uint256 spreadValue) {
        spreadValue =
            _calculateDemandComponentRecFixed(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soap
            ) +
            _calculateAtParComponentRecFixed(
                iporIndexValue,
                exponentialMovingAverage,
                exponentialWeightedMovingVariance
            );
    }

    function _calculateDemandComponentPayFixed(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapPayFixed
    ) internal view returns (uint256) {
        uint256 kfDenominator = _demandComponentMaxLiquidityRedemptionValue -
                _calculateAdjustedUtilizationRatePayFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    _demandComponentLambdaValue
                );

        if (kfDenominator > 0) {
            uint256 kOmegaDenominator = Constants.D18 -
                _calculateSoapPlus(soapPayFixed, payFixedDerivativesBalance);
            if (kOmegaDenominator > 0) {
                return
                    AmmMath.division(
                        _demandComponentKfValue * Constants.D18,
                        kfDenominator
                    ) +
                    AmmMath.division(
                        _demandComponentKOmegaValue * Constants.D18,
                        kOmegaDenominator
                    );
            } else {
                return _maxValue;
            }
        } else {
            return _maxValue;
        }
    }

    function _calculateAtParComponentPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) internal view returns (uint256) {
        if (exponentialWeightedMovingVariance == Constants.D18) {
            return _maxValue;
        } else {
            uint256 historicalDeviation = _calculateHistoricalDeviationPayFixed(
                _atParComponentKHistValue,
                iporIndexValue,
                exponentialMovingAverage,
                _maxValue
            );
            if (historicalDeviation >= _maxValue) {
                return _maxValue;
            } else {
                return
                    AmmMath.division(
                        _atParComponentKVolValue * Constants.D18,
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

    //URlambda_leg(M0)
    function _calculateAdjustedUtilizationRatePayFixed(
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

    function _calculateDemandComponentRecFixed(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapRecFixed
    ) internal view returns (uint256) {
        uint256 kfDenominator = _demandComponentMaxLiquidityRedemptionValue -
                _calculateAdjustedUtilizationRateRecFixed(
                    derivativeDeposit,
                    derivativeOpeningFee,
                    liquidityPool,
                    payFixedDerivativesBalance,
                    recFixedDerivativesBalance,
                    _demandComponentKOmegaValue
                );

        if (kfDenominator > 0) {
            uint256 kOmegaDenominator = Constants.D18 -
                _calculateSoapPlus(soapRecFixed, recFixedDerivativesBalance);
            if (kOmegaDenominator > 0) {
                return
                    AmmMath.division(
                        _demandComponentKfValue * Constants.D18,
                        kfDenominator
                    ) +
                    AmmMath.division(
                        _demandComponentKOmegaValue * Constants.D18,
                        kOmegaDenominator
                    );
            } else {
                return _maxValue;
            }
        } else {
            return _maxValue;
        }
    }

    function _calculateAtParComponentRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) internal view returns (uint256) {
        uint256 maxSpreadValue = _maxValue;

        if (exponentialWeightedMovingVariance == Constants.D18) {
            return maxSpreadValue;
        } else {
            uint256 historicalDeviation = _calculateHistoricalDeviationRecFixed(
                _atParComponentKHistValue,
                iporIndexValue,
                exponentialMovingAverage,
                maxSpreadValue
            );
            if (historicalDeviation >= _maxValue) {
                return _maxValue;
            } else {
                return
                    AmmMath.division(
                        _atParComponentKVolValue * Constants.D18,
                        Constants.D18 - exponentialWeightedMovingVariance
                    ) + historicalDeviation;
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

    function _calculateAdjustedUtilizationRateRecFixed(
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
}

// contract MiltonSpreadModelUsdt is MiltonSpreadModel {
//     constructor(address asset) MiltonSpreadModel(asset) {}
// }

// contract MiltonSpreadModelUsdc is MiltonSpreadModel {
//     constructor(address asset) MiltonSpreadModel(asset) {}
// }

// contract MiltonSpreadModelDai is MiltonSpreadModel {
//     constructor(address asset) MiltonSpreadModel(asset) {}
// }
