// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../libraries/Constants.sol";
import "../libraries/IporMath.sol";
import "../libraries/types/DataTypes.sol";
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
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external pure override returns (uint256 quoteValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksPayFixed(
                soap,
                accruedIpor,
                accruedBalance,
                swapCollateral
            );
        quoteValue = refLeg + spreadPremiums;
    }

    //@dev Quote = RefLeg - SpreadPremiums, RefLeg = min(IPOR, EMAi), Spread = IPOR - RefLeg + SpreadPremiums
    function calculateQuoteReceiveFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external pure override returns (uint256 quoteValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksReceiveFixed(
                soap,
                accruedIpor,
                accruedBalance,
                swapCollateral
            );
			
        if (refLeg > spreadPremiums) {
            quoteValue = refLeg - spreadPremiums;
        } 		
    }

    //@dev Spread = SpreadPremiums + RefLeg - IPOR
    function calculateSpreadPayFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external pure override returns (uint256 spreadValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksPayFixed(
                soap,
                accruedIpor,
                accruedBalance,
                swapCollateral
            );

        spreadValue = spreadPremiums + refLeg - accruedIpor.indexValue;
    }

    event LogDebug(string name, uint256 value);

    //@dev Spread = SpreadPremiums + IPOR - RefLeg
    function calculateSpreadRecFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external override returns (uint256 spreadValue) {
        (
            uint256 spreadPremiums,
            uint256 refLeg
        ) = _calculateQuoteChunksReceiveFixed(
                soap,
                accruedIpor,
                accruedBalance,
                swapCollateral
            );
        emit LogDebug("spreadPremiums", spreadPremiums);
        emit LogDebug("accruedIpor.indexValue", accruedIpor.indexValue);
        emit LogDebug("refLeg", refLeg);
        emit LogDebug("maxValue", _getSpreadPremiumsMaxValue());

        spreadValue = spreadPremiums + accruedIpor.indexValue - refLeg;
    }

    function _calculateQuoteChunksPayFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) internal pure returns (uint256 spreadPremiums, uint256 refLeg) {
        spreadPremiums = _calculateSpreadPremiumsPayFixed(
            soap,
            accruedIpor,
            accruedBalance,
            swapCollateral
        );

        refLeg = _calculateReferenceLegPayFixed(
            accruedIpor.indexValue,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateQuoteChunksReceiveFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) internal pure returns (uint256 spreadPremiums, uint256 refLeg) {
        spreadPremiums = _calculateSpreadPremiumsRecFixed(
            soap,
            accruedIpor,
            accruedBalance,
            swapCollateral
        );

        refLeg = _calculateReferenceLegRecFixed(
            accruedIpor.indexValue,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateSpreadPremiumsPayFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) internal pure returns (uint256 spreadPremiumsValue) {
        require(
            accruedBalance.liquidityPool != 0,
            IporErrors.MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 result = _calculateDemandComponentPayFixed(
            swapCollateral,
            accruedBalance.liquidityPool,
            accruedBalance.payFixedSwaps,
            accruedBalance.receiveFixedSwaps,
            soap
        ) +
            _calculateAtParComponentPayFixed(
                accruedIpor.indexValue,
                accruedIpor.exponentialMovingAverage,
                accruedIpor.exponentialWeightedMovingVariance
            );
        uint256 maxValue = _getSpreadPremiumsMaxValue();
        spreadPremiumsValue = result < maxValue ? result : maxValue;
    }

    function _calculateSpreadPremiumsRecFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) internal pure returns (uint256 spreadValue) {
        require(
            accruedBalance.liquidityPool != 0,
            IporErrors.MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 result = _calculateDemandComponentRecFixed(
            swapCollateral,
            accruedBalance.liquidityPool,
            accruedBalance.payFixedSwaps,
            accruedBalance.receiveFixedSwaps,
            soap
        ) +
            _calculateAtParComponentRecFixed(
                accruedIpor.indexValue,
                accruedIpor.exponentialMovingAverage,
                accruedIpor.exponentialWeightedMovingVariance
            );

        uint256 maxValue = _getSpreadPremiumsMaxValue();
        spreadValue = result < maxValue ? result : maxValue;
    }

    function _calculateDemandComponentPayFixed(
        uint256 swapCollateral,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soapPayFixed
    ) internal pure returns (uint256) {
        uint256 kfDenominator = _getDCMaxLiquidityRedemptionValue() -
            _calculateAdjustedUtilizationRatePayFixed(
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                _getDCLambdaValue()
            );

        if (kfDenominator != 0) {
            if (soapPayFixed > 0) {
                uint256 kOmegaDenominator = Constants.D18 -
                    _calculateSoapPlus(
                        soapPayFixed,
                        payFixedSwapsBalance - swapCollateral
                    );
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
                    return _getSpreadPremiumsMaxValue();
                }
            } else {
                return
                    IporMath.division(
                        _getDCKfValue() * Constants.D18,
                        kfDenominator
                    ) + _getDCKOmegaValue();
            }
        } else {
            return _getSpreadPremiumsMaxValue();
        }
    }

    function _calculateAtParComponentPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) internal pure returns (uint256) {
        uint256 maxValue = _getSpreadPremiumsMaxValue();

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
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRateRecFixed = _calculateUtilizationRateWithoutSwap(
            liquidityPoolBalance,
            receiveFixedSwapsBalance
        );

        uint256 utilizationRatePayFixedWithPosition = _calculateUtilizationRateWithPosition(
                liquidityPoolBalance,
                payFixedSwapsBalance
            );

        uint256 adjustedUtilizationRate = _calculateAdjustedUtilizationRate(
            utilizationRatePayFixedWithPosition,
            utilizationRateRecFixed,
            lambda
        );
        return adjustedUtilizationRate;
    }

    function _calculateDemandComponentRecFixed(
        uint256 swapCollateral,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soapRecFixed
    ) internal pure returns (uint256) {
        uint256 kfDenominator = _getDCMaxLiquidityRedemptionValue() -
            _calculateAdjustedUtilizationRateRecFixed(
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                _getDCLambdaValue()
            );
        if (kfDenominator != 0) {
            if (soapRecFixed > 0) {
                uint256 kOmegaDenominator = Constants.D18 -
                    _calculateSoapPlus(
                        soapRecFixed,
                        receiveFixedSwapsBalance - swapCollateral
                    );
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
                    return _getSpreadPremiumsMaxValue();
                }
            } else {
                return
                    IporMath.division(
                        _getDCKfValue() * Constants.D18,
                        kfDenominator
                    ) + _getDCKOmegaValue();
            }
        } else {
            return _getSpreadPremiumsMaxValue();
        }
    }

    function _calculateAtParComponentRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) internal pure returns (uint256) {
        uint256 maxSpreadValue = _getSpreadPremiumsMaxValue();

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
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRatePayFixed = _calculateUtilizationRateWithoutSwap(
            liquidityPoolBalance,
            payFixedSwapsBalance
        );

        uint256 utilizationRateRecFixedWithPosition = _calculateUtilizationRateWithPosition(
                liquidityPoolBalance,
                receiveFixedSwapsBalance
            );

        uint256 adjustedUtilizationRate = _calculateAdjustedUtilizationRate(
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
