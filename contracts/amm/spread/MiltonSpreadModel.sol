// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadInternal.sol";

contract MiltonSpreadModel is MiltonSpreadInternal, IMiltonSpreadModel {
    using SafeCast for uint256;
    using SafeCast for int256;

    //@dev Quote = RefLeg + SpreadPremiums, RefLeg = max(IPOR, EMAi), Spread = RefLeg + SpreadPremiums - IPOR
    function calculateQuotePayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        (int256 spreadPremiums, uint256 refLeg) = _calculateQuoteChunksPayFixed(
            soap,
            accruedIpor,
            accruedBalance
        );

        int256 intQuoteValue = refLeg.toInt256() + spreadPremiums;

        if (intQuoteValue > 0) {
            return intQuoteValue.toUint256();
        }
    }

    //@dev Quote = RefLeg - SpreadPremiums, RefLeg = min(IPOR, EMAi), Spread = IPOR - RefLeg + SpreadPremiums
    function calculateQuoteReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        (int256 spreadPremiums, uint256 refLeg) = _calculateQuoteChunksReceiveFixed(
            soap,
            accruedIpor,
            accruedBalance
        );

        int256 intQuoteValue = refLeg.toInt256() - spreadPremiums;

        if (intQuoteValue > 0) {
            quoteValue = intQuoteValue.toUint256();
        }
    }

    //@dev Spread = SpreadPremiums + RefLeg - IPOR
    function calculateSpreadPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        (int256 spreadPremiums, uint256 refLeg) = _calculateQuoteChunksPayFixed(
            soap,
            accruedIpor,
            accruedBalance
        );

        spreadValue = spreadPremiums + refLeg.toInt256() - accruedIpor.indexValue.toInt256();
    }

    //@dev Spread = SpreadPremiums + IPOR - RefLeg
    function calculateSpreadReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        (int256 spreadPremiums, uint256 refLeg) = _calculateQuoteChunksReceiveFixed(
            soap,
            accruedIpor,
            accruedBalance
        );

        spreadValue = spreadPremiums + accruedIpor.indexValue.toInt256() - refLeg.toInt256();
    }

    function _calculateQuoteChunksPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums, uint256 refLeg) {
        spreadPremiums = _calculateSpreadPremiumsPayFixed(soap, accruedIpor, accruedBalance);

        refLeg = _calculateReferenceLegPayFixed(
            accruedIpor.indexValue,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateQuoteChunksReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums, uint256 refLeg) {
        spreadPremiums = _calculateSpreadPremiumsReceiveFixed(soap, accruedIpor, accruedBalance);

        refLeg = _calculateReferenceLegReceiveFixed(
            accruedIpor.indexValue,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateSpreadPremiumsPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool != 0,
            MiltonErrors.SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 demandComponent = _calculateDemandComponentPayFixed(
            accruedBalance.liquidityPool,
            accruedBalance.totalCollateralPayFixed,
            accruedBalance.totalCollateralReceiveFixed,
            soap
        );

        int256 mu = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        int256 volatilityAndMeanReversion = _calculateVolatilityAndMeanReversionPayFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            mu
        );

        int256 maxValue = _getSpreadPremiumsMaxValue().toInt256();
        int256 result = demandComponent.toInt256() + volatilityAndMeanReversion;

        spreadPremiums = result < maxValue ? result : maxValue;
    }

    function _calculateSpreadPremiumsReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool != 0,
            MiltonErrors.SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );
        uint256 demandComponent = _calculateDemandComponentReceiveFixed(
            accruedBalance.liquidityPool,
            accruedBalance.totalCollateralPayFixed,
            accruedBalance.totalCollateralReceiveFixed,
            soap
        );

        int256 mu = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        int256 volatilityAndMeanReversion = _calculateVolatilityAndMeanReversionReceiveFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            mu
        );

        int256 maxValue = _getSpreadPremiumsMaxValue().toInt256();
        int256 result = demandComponent.toInt256() + volatilityAndMeanReversion;

        spreadPremiums = result < maxValue ? result : maxValue;
    }

    function _calculateDemandComponentPayFixed(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        int256 soapPayFixed
    ) internal pure returns (uint256) {
        uint256 kfDenominator = _getDCMaxLiquidityRedemptionValue() -
            _calculateAdjustedUtilizationRatePayFixed(
                liquidityPoolBalance,
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance,
                _getDCLambdaValue()
            );

        if (kfDenominator != 0) {
            if (soapPayFixed > 0) {
                uint256 kOmegaDenominator = Constants.D18 -
                    _calculateSoapPlus(soapPayFixed, totalCollateralPayFixedBalance);
                if (kOmegaDenominator != 0) {
                    return
                        IporMath.division(_getDCKfValue() * Constants.D18, kfDenominator) +
                        IporMath.division(_getDCKOmegaValue() * Constants.D18, kOmegaDenominator);
                } else {
                    return _getSpreadPremiumsMaxValue();
                }
            } else {
                return
                    IporMath.division(_getDCKfValue() * Constants.D18, kfDenominator) +
                    _getDCKOmegaValue();
            }
        } else {
            return _getSpreadPremiumsMaxValue();
        }
    }

    //URlambda_leg(M0)
    function _calculateAdjustedUtilizationRatePayFixed(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRateRecFixed = _calculateUtilizationRateWithoutSwap(
            liquidityPoolBalance,
            totalCollateralReceiveFixedBalance
        );

        uint256 utilizationRatePayFixedWithPosition = _calculateUtilizationRateWithPosition(
            liquidityPoolBalance,
            totalCollateralPayFixedBalance
        );

        uint256 adjustedUtilizationRate = _calculateAdjustedUtilizationRate(
            utilizationRatePayFixedWithPosition,
            utilizationRateRecFixed,
            lambda
        );
        return adjustedUtilizationRate;
    }

    function _calculateDemandComponentReceiveFixed(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        int256 soapRecFixed
    ) internal pure returns (uint256) {
        uint256 kfDenominator = _getDCMaxLiquidityRedemptionValue() -
            _calculateAdjustedUtilizationRateRecFixed(
                liquidityPoolBalance,
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance,
                _getDCLambdaValue()
            );
        if (kfDenominator != 0) {
            if (soapRecFixed > 0) {
                uint256 kOmegaDenominator = Constants.D18 -
                    _calculateSoapPlus(soapRecFixed, totalCollateralReceiveFixedBalance);
                if (kOmegaDenominator != 0) {
                    return
                        IporMath.division(_getDCKfValue() * Constants.D18, kfDenominator) +
                        IporMath.division(_getDCKOmegaValue() * Constants.D18, kOmegaDenominator);
                } else {
                    return _getSpreadPremiumsMaxValue();
                }
            } else {
                return
                    IporMath.division(_getDCKfValue() * Constants.D18, kfDenominator) +
                    _getDCKOmegaValue();
            }
        } else {
            return _getSpreadPremiumsMaxValue();
        }
    }

    function _calculateAdjustedUtilizationRateRecFixed(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRatePayFixed = _calculateUtilizationRateWithoutSwap(
            liquidityPoolBalance,
            totalCollateralPayFixedBalance
        );

        uint256 utilizationRateRecFixedWithPosition = _calculateUtilizationRateWithPosition(
            liquidityPoolBalance,
            totalCollateralReceiveFixedBalance
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

    function _calculateReferenceLegReceiveFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue < exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }

    /// @dev Volatility and mean revesion component for Pay Fixed Receive Floating leg. Maximum value between regions.
    function _calculateVolatilityAndMeanReversionPayFixed(uint256 emaVar, int256 mu)
        internal
        pure
        returns (int256)
    {
        int256 regionOne = _volatilityAndMeanReversionPayFixedRegionOne(emaVar, mu);
        int256 regionTwo = _volatilityAndMeanReversionPayFixedRegionTwo(emaVar, mu);
        if (regionOne >= regionTwo) {
            return regionOne;
        } else {
            return regionTwo;
        }
    }

    /// @dev Volatility and mean revesion component for Receive Fixed Pay Floating leg. Minimum value between regions.
    function _calculateVolatilityAndMeanReversionReceiveFixed(uint256 emaVar, int256 mu)
        internal
        pure
        returns (int256)
    {
        int256 regionOne = _volatilityAndMeanReversionReceiveFixedRegionOne(emaVar, mu);
        int256 regionTwo = _volatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, mu);
        if (regionOne >= regionTwo) {
            return regionTwo;
        } else {
            return regionOne;
        }
    }

    function _volatilityAndMeanReversionPayFixedRegionOne(uint256 emaVar, int256 mu)
        internal
        pure
        returns (int256)
    {
        return
            _getPayFixedRegionOneBase() +
            IporMath.divisionInt(
                _getPayFixedRegionOneSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getPayFixedRegionOneSlopeForMeanReversion() *
                    mu,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionPayFixedRegionTwo(uint256 emaVar, int256 mu)
        internal
        pure
        returns (int256)
    {
        return
            _getPayFixedRegionTwoBase() +
            IporMath.divisionInt(
                _getPayFixedRegionTwoSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getPayFixedRegionTwoSlopeForMeanReversion() *
                    mu,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionOne(uint256 emaVar, int256 mu)
        internal
        pure
        returns (int256)
    {
        return
            _getReceiveFixedRegionOneBase() +
            IporMath.divisionInt(
                _getReceiveFixedRegionOneSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getReceiveFixedRegionOneSlopeForMeanReversion() *
                    mu,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionTwo(uint256 emaVar, int256 mu)
        internal
        pure
        returns (int256)
    {
        return
            _getReceiveFixedRegionTwoBase() +
            IporMath.divisionInt(
                _getReceiveFixedRegionTwoSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getReceiveFixedRegionTwoSlopeForMeanReversion() *
                    mu,
                Constants.D18_INT
            );
    }
}
