// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../libraries/Constants.sol";
import "../libraries/IporMath.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IWarren.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import {IporErrors} from "../IporErrors.sol";
import "./MiltonSpreadModelCore.sol";
import "../configuration/MiltonSpreadConfiguration.sol";

contract MiltonSpreadModel is
    UUPSUpgradeable,
    OwnableUpgradeable,
    MiltonSpreadModelCore,
    MiltonSpreadConfiguration,
    IMiltonSpreadModel
{
    function initialize() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //@dev Quote = RefLeg + SpreadPremiums, RefLeg = max(IPOR, EMAi), Spread = RefLeg + SpreadPremiums - IPOR
    function calculateQuotePayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view override returns (uint256 quoteValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksPayFixed(
                calculateTimestamp,
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                miltonStorage
            );
        quoteValue = refLeg + spreadPremiums;
    }

    //@dev Quote = RefLeg - SpreadPremiums, RefLeg = min(IPOR, EMAi), Spread = IPOR - RefLeg + SpreadPremiums
    function calculateQuoteReceiveFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view override returns (uint256 quoteValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksReceiveFixed(
                calculateTimestamp,
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                miltonStorage
            );

        if (accruedIpor.indexValue > spreadPremiums) {
            quoteValue = refLeg - spreadPremiums;
        } else {
            quoteValue = 0;
        }
    }

    //@dev Spread = SpreadPremiums + RefLeg - IPOR
    function calculateSpreadPayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view override returns (uint256 spreadValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksPayFixed(
                calculateTimestamp,
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                miltonStorage
            );

        spreadValue = spreadPremiums + refLeg - accruedIpor.indexValue;
    }

    //@dev Spread = SpreadPremiums + IPOR - RefLeg
    function calculateSpreadRecFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) external view override returns (uint256 spreadValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksReceiveFixed(
                calculateTimestamp,
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                miltonStorage
            );

        spreadValue = spreadPremiums + accruedIpor.indexValue - refLeg;
    }

    function calculatePartialSpreadPayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        IMiltonStorage miltonStorage
    ) external view override returns (uint256 spreadValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksPayFixed(
                calculateTimestamp,
                accruedIpor,
                0,
                0,
                miltonStorage
            );

        spreadValue = spreadPremiums + refLeg - accruedIpor.indexValue;
    }

    function calculatePartialSpreadRecFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        IMiltonStorage miltonStorage
    ) external view override returns (uint256 spreadValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksReceiveFixed(
                calculateTimestamp,
                accruedIpor,
                0,
                0,
                miltonStorage
            );

        spreadValue = spreadPremiums + accruedIpor.indexValue - refLeg;
    }

    function _calculateQuoteChunksPayFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) internal view returns (uint256 spreadPremiums, uint256 refLeg) {
        spreadPremiums = _calculateSpreadPremiumsPayFixed(
            accruedIpor,
            swapCollateral,
            swapOpeningFee,
            miltonStorage.getBalance(),
            miltonStorage.calculateSoapPayFixed(
                accruedIpor.ibtPrice,
                calculateTimestamp
            )
        );

        require(
            accruedIpor.indexValue >= spreadPremiums,
            IporErrors.MILTON_SPREAD_CANNOT_BE_HIGHER_THAN_IPOR_INDEX
        );

        refLeg = _calculateReferenceLegPayFixed(
            accruedIpor.indexValue,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateQuoteChunksReceiveFixed(
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        IMiltonStorage miltonStorage
    ) internal view returns (uint256 spreadPremiums, uint256 refLeg) {
        spreadPremiums = _calculateSpreadPremiumsRecFixed(
            accruedIpor,
            swapCollateral,
            swapOpeningFee,
            miltonStorage.getBalance(),
            miltonStorage.calculateSoapReceiveFixed(
                accruedIpor.ibtPrice,
                calculateTimestamp
            )
        );

        require(
            accruedIpor.indexValue >= spreadPremiums,
            IporErrors.MILTON_SPREAD_CANNOT_BE_HIGHER_THAN_IPOR_INDEX
        );

        refLeg = _calculateReferenceLegRecFixed(
            accruedIpor.indexValue,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateSpreadPremiumsPayFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        DataTypes.MiltonTotalBalanceMemory memory balance,
        int256 soap
    ) internal pure returns (uint256 spreadValue) {
        require(
            balance.liquidityPool + swapOpeningFee != 0,
            IporErrors.MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 result = _calculateDemandComponentPayFixed(
            swapCollateral,
            swapOpeningFee,
            balance.liquidityPool,
            balance.payFixedSwaps,
            balance.receiveFixedSwaps,
            soap
        ) +
            _calculateAtParComponentPayFixed(
                accruedIpor.indexValue,
                accruedIpor.exponentialMovingAverage,
                accruedIpor.exponentialWeightedMovingVariance
            );
        uint256 maxValue = _getSpreadMaxValue();
        spreadValue = result < maxValue ? result : maxValue;
    }

    function _calculateSpreadPremiumsRecFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        DataTypes.MiltonTotalBalanceMemory memory balance,
        int256 soap
    ) internal pure returns (uint256 spreadValue) {
        require(
            balance.liquidityPool + swapOpeningFee != 0,
            IporErrors.MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 result = _calculateDemandComponentRecFixed(
            swapCollateral,
            swapOpeningFee,
            balance.liquidityPool,
            balance.payFixedSwaps,
            balance.receiveFixedSwaps,
            soap
        ) +
            _calculateAtParComponentRecFixed(
                accruedIpor.indexValue,
                accruedIpor.exponentialMovingAverage,
                accruedIpor.exponentialWeightedMovingVariance
            );

        uint256 maxValue = _getSpreadMaxValue();
        spreadValue = result < maxValue ? result : maxValue;
    }

    function _calculateDemandComponentPayFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soapPayFixed
    ) internal pure returns (uint256) {
        uint256 kfDenominator = _getDCMaxLiquidityRedemptionValue() -
            _calculateAdjustedUtilizationRatePayFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                _getDCLambdaValue()
            );

        if (kfDenominator != 0) {
            if (soapPayFixed > 0) {
                uint256 kOmegaDenominator = Constants.D18 -
                    _calculateSoapPlus(soapPayFixed, payFixedSwapsBalance);
                if (kOmegaDenominator != 0) {
                    return
                        IporMath.division(
                            _getDCKfValue() * Constants.D18,
                            kfDenominator
                        ) +
                        IporMath.division(
                            _getDCKOmegaValue() * Constants.D18,
                            kOmegaDenominator
                        );
                } else {
                    return _getSpreadMaxValue();
                }
            } else {
                return
                    IporMath.division(
                        _getDCKfValue() * Constants.D18,
                        kfDenominator
                    ) + _getDCKOmegaValue();
            }
        } else {
            return _getSpreadMaxValue();
        }
    }

    function _calculateAtParComponentPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) internal pure returns (uint256) {
        uint256 maxValue = _getSpreadMaxValue();

        if (exponentialWeightedMovingVariance == Constants.D18) {
            return maxValue;
        } else {
            uint256 historicalDeviation = _calculateHistoricalDeviationPayFixed(
                _getAtParComponentKHistValue(),
                iporIndexValue,
                exponentialMovingAverage,
                maxValue
            );

            if (historicalDeviation < maxValue) {
                return
                    IporMath.division(
                        _getAtParComponentKVolValue() * Constants.D18,
                        Constants.D18 - exponentialWeightedMovingVariance
                    ) + historicalDeviation;
            } else {
                return maxValue;
            }
        }
    }

    //URlambda_leg(M0)
    function _calculateAdjustedUtilizationRatePayFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRateRecFixed = _calculateUtilizationRateWithoutSwap(
            swapOpeningFee,
            liquidityPoolBalance,
            receiveFixedSwapsBalance
        );

        uint256 utilizationRatePayFixedWithPosition = _calculateUtilizationRateWithPosition(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance
            );

        uint256 adjustedUtilizationRate = _calculateImbalanceFactorWithLambda(
            utilizationRatePayFixedWithPosition,
            utilizationRateRecFixed,
            lambda
        );
        return adjustedUtilizationRate;
    }

    function _calculateDemandComponentRecFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soapRecFixed
    ) internal pure returns (uint256) {
        uint256 kfDenominator = _getDCMaxLiquidityRedemptionValue() -
            _calculateAdjustedUtilizationRateRecFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                _getDCLambdaValue()
            );
        if (kfDenominator != 0) {
            if (soapRecFixed > 0) {
                uint256 kOmegaDenominator = Constants.D18 -
                    _calculateSoapPlus(soapRecFixed, receiveFixedSwapsBalance);
                if (kOmegaDenominator != 0) {
                    return
                        IporMath.division(
                            _getDCKfValue() * Constants.D18,
                            kfDenominator
                        ) +
                        IporMath.division(
                            _getDCKOmegaValue() * Constants.D18,
                            kOmegaDenominator
                        );
                } else {
                    return _getSpreadMaxValue();
                }
            } else {
                return
                    IporMath.division(
                        _getDCKfValue() * Constants.D18,
                        kfDenominator
                    ) + _getDCKOmegaValue();
            }
        } else {
            return _getSpreadMaxValue();
        }
    }

    function _calculateAtParComponentRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) internal pure returns (uint256) {
        uint256 maxSpreadValue = _getSpreadMaxValue();

        if (exponentialWeightedMovingVariance == Constants.D18) {
            return maxSpreadValue;
        } else {
            uint256 historicalDeviation = _calculateHistoricalDeviationRecFixed(
                _getAtParComponentKHistValue(),
                iporIndexValue,
                exponentialMovingAverage,
                maxSpreadValue
            );
            if (historicalDeviation < maxSpreadValue) {
                return
                    IporMath.division(
                        _getAtParComponentKVolValue() * Constants.D18,
                        Constants.D18 - exponentialWeightedMovingVariance
                    ) + historicalDeviation;
            } else {
                return maxSpreadValue;
            }
        }
    }

    function _calculateAdjustedUtilizationRateRecFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRatePayFixed = _calculateUtilizationRateWithoutSwap(
            swapOpeningFee,
            liquidityPoolBalance,
            payFixedSwapsBalance
        );

        uint256 utilizationRateRecFixedWithPosition = _calculateUtilizationRateWithPosition(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                receiveFixedSwapsBalance
            );

        uint256 adjustedUtilizationRate = _calculateImbalanceFactorWithLambda(
            utilizationRateRecFixedWithPosition,
            utilizationRatePayFixed,
            lambda
        );
        return adjustedUtilizationRate;
    }

    function _calculateReferenceLegPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue > exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }

    function _calculateReferenceLegRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue < exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }
}
