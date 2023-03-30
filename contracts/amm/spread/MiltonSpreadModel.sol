// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/IMiltonSpreadModel.sol";
import "./MiltonSpreadInternal.sol";

abstract contract MiltonSpreadModel is MiltonSpreadInternal, IMiltonSpreadModel {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 _weightedNotionalPayFixed;
    uint256 _weightedNotionalReceiveFixed;

    uint256 _lastUpdateTimePayFixed;
    uint256 _lastUpdateTimeReceiveFixed;

    uint256 _collateralOpenInBlockPayFixed;
    uint256 _collateralOpenInBlockReceiveFixed;
    uint256 _notionalOpenInBlockPayFixed;
    uint256 _notionalOpenInBlockReceiveFixed;

    struct SpreadCalculation {
        uint256 lpBalance;
        uint256 collateralPayFixed;
        uint256 collateralReceiveFixed;
        uint256 notionalReceiveFixed;
        uint256 notionalPayFixed;
        uint256 iporRate;
        int256 volatilitySpread;
        uint256 weightedNotionalReceiveFixed;
        uint256 weightedNotionalPayFixed;
    }

    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance,
        uint256 swapCollateral,
        uint256 swapNotional
    ) external view override returns (uint256 quoteValue) {
        int256 volatilitySpread = _calculateSpreadPremiumsPayFixed(accruedIpor, accruedBalance);

        SpreadCalculation memory spreadData = SpreadCalculation(
            accruedBalance.liquidityPool,
            accruedBalance.totalCollateralPayFixed,
            accruedBalance.totalCollateralReceiveFixed,
            accruedBalance.totalNotionalReceiveFixed,
            accruedBalance.totalNotionalPayFixed,
            accruedIpor.indexValue,
            volatilitySpread,
            _weightedNotionalReceiveFixed,
            _weightedNotionalPayFixed
        );

        uint256 spread = calculateSwapSpreadPayFixed(spreadData, swapCollateral, swapNotional);
        _updateWeightedNotionalPayFixed(
            swapCollateral,
            swapNotional,
            spreadData.weightedNotionalPayFixed
        );

        return accruedIpor.indexValue + spread;
    }

    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        int256 spreadPremiums = _calculateSpreadPremiumsReceiveFixed(accruedIpor, accruedBalance);

        int256 intQuoteValueWithIpor = accruedIpor.indexValue.toInt256() + spreadPremiums;

        quoteValue = _calculateReferenceLegReceiveFixed(
            intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0,
            accruedIpor.exponentialMovingAverage
        );
    }

    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        int256 volatilitySpread = _calculateSpreadPremiumsPayFixed(accruedIpor, accruedBalance);

        SpreadCalculation memory spreadData = SpreadCalculation(
            accruedBalance.liquidityPool,
            accruedBalance.totalCollateralPayFixed,
            accruedBalance.totalCollateralReceiveFixed,
            accruedBalance.totalNotionalReceiveFixed,
            accruedBalance.totalNotionalPayFixed,
            accruedIpor.indexValue,
            volatilitySpread,
            _weightedNotionalReceiveFixed,
            _weightedNotionalPayFixed
        );
        spreadValue = calculateBasePayFixedSpread(spreadData).toInt256();
    }

    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsReceiveFixed(accruedIpor, accruedBalance);
    }

    function _calculateSpreadPremiumsPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionPayFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma
        );
    }

    function _calculateSpreadPremiumsReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionReceiveFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma
        );
    }

    function calculateSwapSpreadPayFixed(
        SpreadCalculation memory spreadData,
        uint256 swapCollateral,
        uint256 swapNotional
    ) public view returns (uint256) {
        uint256 baseSpread;
        if (_lastUpdateTimePayFixed == block.timestamp) {
            spreadData.weightedNotionalPayFixed -= _notionalOpenInBlockPayFixed;
            spreadData.weightedNotionalReceiveFixed -= _notionalOpenInBlockReceiveFixed;
            spreadData.collateralPayFixed -= _collateralOpenInBlockPayFixed;
            spreadData.collateralReceiveFixed -= _collateralOpenInBlockReceiveFixed;
            spreadData.notionalReceiveFixed -= _notionalOpenInBlockReceiveFixed;
            spreadData.notionalPayFixed -= _notionalOpenInBlockPayFixed;
            baseSpread = calculateBasePayFixedSpread(spreadData);
        } else {
            baseSpread = calculateBasePayFixedSpread(spreadData);
        }
        uint256 premium = IporMath.division(
            (spreadData.collateralPayFixed + IporMath.division(swapCollateral, 2)) * 1e18,
            spreadData.lpBalance
        );

        return baseSpread + premium;
    }

    function _updateWeightedNotionalPayFixed(
        uint256 newSwapCollateral,
        uint256 newSwapNotional,
        uint256 weightedNotionalPayFixed
    ) internal {
        if (weightedNotionalPayFixed == 0) {
            _weightedNotionalPayFixed = calculateWeightedNotional(newSwapNotional, 0);
        } else {
            uint256 oldWeightedNotionalPayFixed = calculateWeightedNotional(
                weightedNotionalPayFixed,
                block.timestamp - _lastUpdateTimePayFixed
            );
            _weightedNotionalPayFixed = newSwapNotional + oldWeightedNotionalPayFixed;
        }
        if (_lastUpdateTimePayFixed == block.timestamp) {
            _collateralOpenInBlockPayFixed += newSwapCollateral;
            _notionalOpenInBlockPayFixed += newSwapNotional;
        } else {
            _collateralOpenInBlockPayFixed = newSwapCollateral;
            _notionalOpenInBlockPayFixed = newSwapNotional;
            _lastUpdateTimePayFixed = block.timestamp;
        }
    }

    function updateWeightedNotionalReceiveFixed(
        uint256 newSwapCollateral,
        uint256 newSwapNotional,
        uint256 weightedNotionalReceiveFixed
    ) external {
        if (weightedNotionalReceiveFixed == 0) {
            _weightedNotionalReceiveFixed = calculateWeightedNotional(newSwapNotional, 0);
        } else {
            uint256 oldWeightedNotionalReceiveFixed = calculateWeightedNotional(
                weightedNotionalReceiveFixed,
                block.timestamp - _lastUpdateTimeReceiveFixed
            );
            _weightedNotionalReceiveFixed = newSwapNotional + oldWeightedNotionalReceiveFixed;
        }
        if (_lastUpdateTimeReceiveFixed == block.timestamp) {
            _collateralOpenInBlockReceiveFixed += newSwapCollateral;
            _notionalOpenInBlockReceiveFixed += newSwapNotional;
        } else {
            _collateralOpenInBlockReceiveFixed = newSwapCollateral;
            _notionalOpenInBlockReceiveFixed = newSwapNotional;
            _lastUpdateTimeReceiveFixed = block.timestamp;
        }
    }

    function calculateWeightedNotional(uint256 weightedNotional, uint256 timeFromLastUpdate)
        public
        pure
        returns (uint256)
    {
        if (timeFromLastUpdate > 28 * 24 * 60 * 60) {
            return 0;
        }
        return weightedNotional * (1 - (timeFromLastUpdate / 28) * 24 * 60 * 60);
    }

    function calculateBasePayFixedSpread(SpreadCalculation memory spreadData)
        public
        returns (uint256 basePayFixedSpread)
    {
        // TODO: extract to constant or put into  SpreadCalculation
        uint256 weightedTimeToMaturity = 28;
        uint256 minAnticipatedSustainedRate = 0;
        uint256 maxAnticipatedSustainedRate = 1e16;
        uint256 maturity = 28;

        uint256 lpDepth = calculateLpDepth(
            spreadData.lpBalance,
            spreadData.collateralPayFixed,
            spreadData.collateralReceiveFixed
        );

        uint256 maxDdReceiveFixed = calculateMaxDdReceiveFixed(
            spreadData.collateralReceiveFixed,
            spreadData.notionalReceiveFixed,
            spreadData.iporRate,
            minAnticipatedSustainedRate,
            maturity
        );

        uint256 maxDdPayFixed = calculateMaxDdPayFixed(
            spreadData.collateralPayFixed,
            spreadData.notionalPayFixed,
            spreadData.iporRate,
            maxAnticipatedSustainedRate,
            maturity
        );

        uint256 maxDdAdjustedReceiveFixed = calculateMaxDdAdjusted(
            maxDdReceiveFixed,
            maxDdPayFixed,
            weightedTimeToMaturity,
            maturity,
            spreadData.weightedNotionalReceiveFixed,
            spreadData.weightedNotionalPayFixed,
            spreadData.notionalReceiveFixed
        );

        uint256 maxDdAdjustedPayFixed = calculateMaxDdAdjusted(
            maxDdPayFixed,
            maxDdReceiveFixed,
            weightedTimeToMaturity,
            maturity,
            spreadData.weightedNotionalPayFixed,
            spreadData.weightedNotionalReceiveFixed,
            spreadData.notionalPayFixed
        );

        uint256 slope = _calculateSlope(
            spreadData.weightedNotionalPayFixed,
            spreadData.notionalPayFixed
        );

        basePayFixedSpread = calculateNewSpread(
            maxDdAdjustedPayFixed,
            lpDepth,
            slope,
            spreadData.volatilitySpread
        );
    }

    function calculateBaseReceiveFixedSpread(SpreadCalculation memory spreadData)
        public
        returns (uint256 baseReceiveFixedSpread)
    {
        // TODO: extract to constant or put into  SpreadCalculation
        uint256 weightedTimeToMaturity = 28;
        uint256 minAnticipatedSustainedRate = 0;
        uint256 maxAnticipatedSustainedRate = 1e16;
        uint256 maturity = 28;

        uint256 lpDepth = calculateLpDepth(
            spreadData.lpBalance,
            spreadData.collateralPayFixed,
            spreadData.collateralReceiveFixed
        );

        uint256 maxDdReceiveFixed = calculateMaxDdReceiveFixed(
            spreadData.collateralReceiveFixed,
            spreadData.notionalReceiveFixed,
            spreadData.iporRate,
            minAnticipatedSustainedRate,
            maturity
        );

        uint256 maxDdPayFixed = calculateMaxDdPayFixed(
            spreadData.collateralPayFixed,
            spreadData.notionalPayFixed,
            spreadData.iporRate,
            maxAnticipatedSustainedRate,
            maturity
        );

        uint256 maxDdAdjustedReceiveFixed = calculateMaxDdAdjusted(
            maxDdReceiveFixed,
            maxDdPayFixed,
            weightedTimeToMaturity,
            maturity,
            spreadData.weightedNotionalReceiveFixed,
            spreadData.weightedNotionalPayFixed,
            spreadData.notionalReceiveFixed
        );

        uint256 maxDdAdjustedPayFixed = calculateMaxDdAdjusted(
            maxDdPayFixed,
            maxDdReceiveFixed,
            weightedTimeToMaturity,
            maturity,
            spreadData.weightedNotionalPayFixed,
            spreadData.weightedNotionalReceiveFixed,
            spreadData.notionalPayFixed
        );

        uint256 slope = _calculateSlope(
            spreadData.weightedNotionalReceiveFixed,
            spreadData.notionalReceiveFixed
        );

        baseReceiveFixedSpread = calculateNewSpread(
            maxDdAdjustedReceiveFixed,
            lpDepth,
            slope,
            spreadData.volatilitySpread
        );
    }

    //    accrued_balance - abs(total_collateral_pay_fixed - total_collateral_receive_fixed)
    //    always: lpDepth > totalCollateralPayFixed, totalCollateralReceiveFixed
    function calculateLpDepth(
        uint256 lpBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) public view returns (uint256 lpDepth) {
        if (totalCollateralPayFixed >= totalCollateralReceiveFixed) {
            lpDepth = lpBalance + totalCollateralReceiveFixed - totalCollateralPayFixed;
        } else {
            lpDepth = lpBalance + totalCollateralPayFixed - totalCollateralReceiveFixed;
        }
    }

    function calculateMaxDdReceiveFixed(
        uint256 collateralReceiveFixed,
        uint256 notionalReceiveFixed,
        uint256 iporRate,
        uint256 minAnticipatedSustainedRate,
        uint256 maturity
    ) public view returns (uint256 maxDdReceiveFixed) {
        uint256 notionalIndex = notionalReceiveFixed * iporRate;
        uint256 notionalMin = notionalReceiveFixed * minAnticipatedSustainedRate;
        if (notionalIndex > notionalMin) {
            uint256 tempDD = (notionalIndex - notionalMin) * (maturity / 365);
            if (tempDD > collateralReceiveFixed) {
                maxDdReceiveFixed = collateralReceiveFixed;
            } else {
                maxDdReceiveFixed = tempDD;
            }
        } else {
            maxDdReceiveFixed = collateralReceiveFixed;
        }
    }

    function calculateMaxDdPayFixed(
        uint256 collateralPayFixed,
        uint256 notionalPayFixed,
        uint256 iporRate,
        uint256 maxAnticipatedSustainedRate,
        uint256 maturity
    ) public view returns (uint256 maxDdPayFixed) {
        uint256 notionalIndex = notionalPayFixed * iporRate;
        uint256 notionalMax = notionalPayFixed * maxAnticipatedSustainedRate;
        if (notionalIndex < notionalMax) {
            uint256 tempDD = (notionalMax - notionalIndex) * (maturity / 365);
            if (tempDD > collateralPayFixed) {
                maxDdPayFixed = collateralPayFixed;
            } else {
                maxDdPayFixed = tempDD;
            }
        } else {
            maxDdPayFixed = collateralPayFixed;
        }
    }

    function calculateMaxDdAdjusted(
        uint256 maxDdT1,
        uint256 maxDdT2,
        uint256 weightedTimeToMaturity,
        uint256 maturity,
        uint256 weightedNotionalT1,
        uint256 weightedNotionalT2,
        uint256 totalNotionalPerLeg
    ) public view returns (uint256 maxDdAdjusted) {
        if (maxDdT1 < maxDdT2) {
            maxDdAdjusted = 0;
        } else if (maxDdT1 == maxDdT2) {
            maxDdAdjusted = weightedNotionalT1 > weightedNotionalT2
                ? IporMath.divisionWithoutRound(
                    _calculateSlope(weightedNotionalT1, totalNotionalPerLeg) * maxDdT1,
                    1e18
                )
                : 0;
        } else {
            maxDdAdjusted = (maxDdT1 - maxDdT2) * (weightedTimeToMaturity / maturity);
        }
    }

    function calculateNewSpread(
        uint256 maxDdAdjusted,
        uint256 lpDepth,
        uint256 slope,
        int256 volatilitySpread
    ) public view returns (uint256 spread) {
        uint256 tempParam = 1;
        if (lpDepth == 0) {
            spread = IporMath.absoluteValue(volatilitySpread);
        }
        spread =
            IporMath.divisionWithoutRound(maxDdAdjusted * slope * tempParam, lpDepth) +
            IporMath.absoluteValue(volatilitySpread);
    }

    function _calculateSlope(uint256 weightedNotional, uint256 totalNotionalPerLeg)
        internal
        view
        returns (uint256 slope)
    {
        slope = IporMath.divisionWithoutRound(weightedNotional * 1e18, totalNotionalPerLeg);
    }

    /// @dev Volatility and mean revesion component for Pay Fixed Receive Floating leg. Maximum value between regions.
    function _calculateVolatilityAndMeanReversionPayFixed(uint256 emaVar, int256 diffIporIndexEma)
        internal
        view
        returns (int256)
    {
        int256 regionOne = _volatilityAndMeanReversionPayFixedRegionOne(emaVar, diffIporIndexEma);
        int256 regionTwo = _volatilityAndMeanReversionPayFixedRegionTwo(emaVar, diffIporIndexEma);
        if (regionOne >= regionTwo) {
            return regionOne;
        } else {
            return regionTwo;
        }
    }

    /// @dev Volatility and mean revesion component for Receive Fixed Pay Floating leg. Minimum value between regions.
    function _calculateVolatilityAndMeanReversionReceiveFixed(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) internal view returns (int256) {
        int256 regionOne = _volatilityAndMeanReversionReceiveFixedRegionOne(
            emaVar,
            diffIporIndexEma
        );
        int256 regionTwo = _volatilityAndMeanReversionReceiveFixedRegionTwo(
            emaVar,
            diffIporIndexEma
        );

        if (regionOne >= regionTwo) {
            return regionTwo;
        } else {
            return regionOne;
        }
    }

    function _volatilityAndMeanReversionPayFixedRegionOne(uint256 emaVar, int256 diffIporIndexEma)
        internal
        view
        returns (int256)
    {
        return
            _getPayFixedRegionOneBase() +
            IporMath.divisionInt(
                _getPayFixedRegionOneSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getPayFixedRegionOneSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionPayFixedRegionTwo(uint256 emaVar, int256 diffIporIndexEma)
        internal
        view
        returns (int256)
    {
        return
            _getPayFixedRegionTwoBase() +
            IporMath.divisionInt(
                _getPayFixedRegionTwoSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getPayFixedRegionTwoSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) internal view returns (int256) {
        return
            _getReceiveFixedRegionOneBase() +
            IporMath.divisionInt(
                _getReceiveFixedRegionOneSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getReceiveFixedRegionOneSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) internal view returns (int256) {
        return
            _getReceiveFixedRegionTwoBase() +
            IporMath.divisionInt(
                _getReceiveFixedRegionTwoSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getReceiveFixedRegionTwoSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
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
}
