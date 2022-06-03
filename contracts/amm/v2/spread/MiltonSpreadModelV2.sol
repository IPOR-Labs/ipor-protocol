// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "../../../libraries/errors/MiltonErrorsV2.sol";
import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/IMiltonSpreadModelV2.sol";
import "./MiltonSpreadInternalV2.sol";

contract MiltonSpreadModelV2 is MiltonSpreadInternalV2, IMiltonSpreadModelV2 {
    using SafeCast for uint256;
    using SafeCast for int256;

    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure override returns (uint256 quoteValue) {
        int256 spreadPremiums = _calculateSpreadPremiumsPayFixed(accruedIpor, accruedBalance);

        int256 intQuoteValue = accruedIpor.indexValue.toInt256() + spreadPremiums;

        if (intQuoteValue > 0) {
            return intQuoteValue.toUint256();
        }
    }

    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure override returns (uint256 quoteValue) {
        int256 spreadPremiums = _calculateSpreadPremiumsReceiveFixed(accruedIpor, accruedBalance);

        int256 intQuoteValue = accruedIpor.indexValue.toInt256() - spreadPremiums;

        if (intQuoteValue > 0) {
            quoteValue = intQuoteValue.toUint256();
        }
    }

    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsPayFixed(accruedIpor, accruedBalance);
    }

    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsReceiveFixed(accruedIpor, accruedBalance);
    }

    function _calculateSpreadPremiumsPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal pure returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool != 0,
            MiltonErrorsV2.SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
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
    ) internal pure returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool != 0,
            MiltonErrorsV2.SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionReceiveFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma
        );
    }

    /// @dev Volatility and mean revesion component for Pay Fixed Receive Floating leg. Maximum value between regions.
    function _calculateVolatilityAndMeanReversionPayFixed(uint256 emaVar, int256 diffIporIndexEma)
        internal
        pure
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
    ) internal pure returns (int256) {
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
        pure
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
        pure
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
    ) internal pure returns (int256) {
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
    ) internal pure returns (int256) {
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
}