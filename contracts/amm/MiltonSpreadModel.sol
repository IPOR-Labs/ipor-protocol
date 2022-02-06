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

    function calculatePartialSpreadPayFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor
    ) external view override returns (uint256 spreadValue) {
        DataTypes.MiltonTotalBalanceMemory memory balance = miltonStorage
            .getBalance();

        return
            _calculateSpreadPayFixed(
                accruedIpor,
                0,
                0,
                balance.liquidityPool,
                balance.payFixedSwaps,
                balance.receiveFixedSwaps,
                miltonStorage.calculateSoapPayFixed(
                    accruedIpor.ibtPrice,
                    calculateTimestamp
                )
            );
    }

    function calculateSpreadPayFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee
    ) external view override returns (uint256 spreadValue) {
        DataTypes.MiltonTotalBalanceMemory memory balance = miltonStorage
            .getBalance();

        return
            _calculateSpreadPayFixed(
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                balance.liquidityPool,
                balance.payFixedSwaps,
                balance.receiveFixedSwaps,
                miltonStorage.calculateSoapPayFixed(
                    accruedIpor.ibtPrice,
                    calculateTimestamp
                )
            );
    }

    function calculatePartialSpreadRecFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor
    ) external view override returns (uint256 spreadValue) {
        DataTypes.MiltonTotalBalanceMemory memory balance = miltonStorage
            .getBalance();

        return
            _calculateSpreadRecFixed(
                accruedIpor,
                0,
                0,
                balance.liquidityPool,
                balance.payFixedSwaps,
                balance.receiveFixedSwaps,
                miltonStorage.calculateSoapReceiveFixed(
                    accruedIpor.ibtPrice,
                    calculateTimestamp
                )
            );
    }

    function calculateSpreadRecFixed(
        IMiltonStorage miltonStorage,
        uint256 calculateTimestamp,
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee
    ) external view override returns (uint256 spreadValue) {
        DataTypes.MiltonTotalBalanceMemory memory balance = miltonStorage
            .getBalance();

        return
            _calculateSpreadRecFixed(
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                balance.liquidityPool,
                balance.payFixedSwaps,
                balance.receiveFixedSwaps,
                miltonStorage.calculateSoapReceiveFixed(
                    accruedIpor.ibtPrice,
                    calculateTimestamp
                )
            );
    }

    function _calculateSpreadPayFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soap
    ) internal pure returns (uint256 spreadValue) {
        require(
            liquidityPoolBalance + swapOpeningFee != 0,
            IporErrors.MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 result = _calculateDemandComponentPayFixed(
            swapCollateral,
            swapOpeningFee,
            liquidityPoolBalance,
            payFixedSwapsBalance,
            receiveFixedSwapsBalance,
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

    function _calculateSpreadRecFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soap
    ) internal pure returns (uint256 spreadValue) {
        require(
            liquidityPoolBalance + swapOpeningFee != 0,
            IporErrors.MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 result = _calculateDemandComponentRecFixed(
            swapCollateral,
            swapOpeningFee,
            liquidityPoolBalance,
            payFixedSwapsBalance,
            receiveFixedSwapsBalance,
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
}
