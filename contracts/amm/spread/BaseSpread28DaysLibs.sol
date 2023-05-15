// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/Constants.sol";
import "./Spread28DaysConfigLibs.sol";

library BaseSpread28DaysLibs {
    using SafeCast for int256;
    using SafeCast for uint256;

    function _calculateSpreadPremiumsPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionPayFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma,
            config
        );
    }

    /// @dev Volatility and mean revesion component for Pay Fixed Receive Floating leg. Maximum value between regions.
    function _calculateVolatilityAndMeanReversionPayFixed(
        uint256 emaVar,
        int256 diffIporIndexEma,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256) {
        int256 regionOne = _volatilityAndMeanReversionPayFixedRegionOne(
            emaVar,
            diffIporIndexEma,
            config
        );
        int256 regionTwo = _volatilityAndMeanReversionPayFixedRegionTwo(
            emaVar,
            diffIporIndexEma,
            config
        );
        if (regionOne >= regionTwo) {
            return regionOne;
        } else {
            return regionTwo;
        }
    }

    function _volatilityAndMeanReversionPayFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256) {
        return
            config.payFixedRegionOneBase +
            IporMath.divisionInt(
                config.payFixedRegionOneSlopeForVolatility *
                    emaVar.toInt256() +
                    config.payFixedRegionOneSlopeForMeanReversion *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionPayFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256) {
        return
            config.payFixedRegionTwoBase +
            IporMath.divisionInt(
                config.payFixedRegionTwoSlopeForVolatility *
                    emaVar.toInt256() +
                    config.payFixedRegionTwoSlopeForMeanReversion *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _calculateSpreadPremiumsReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
        accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionReceiveFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma,
            config
        );
    }

    /// @dev Volatility and mean revesion component for Receive Fixed Pay Floating leg. Minimum value between regions.
    function _calculateVolatilityAndMeanReversionReceiveFixed(
        uint256 emaVar,
        int256 diffIporIndexEma,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256) {
        int256 regionOne = _volatilityAndMeanReversionReceiveFixedRegionOne(
            emaVar,
            diffIporIndexEma,
            config
        );
        int256 regionTwo = _volatilityAndMeanReversionReceiveFixedRegionTwo(
            emaVar,
            diffIporIndexEma,
            config
        );

        if (regionOne >= regionTwo) {
            return regionTwo;
        } else {
            return regionOne;
        }
    }

    function _volatilityAndMeanReversionReceiveFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256) {
        return
        config.receiveFixedRegionOneBase +
        IporMath.divisionInt(
            config.receiveFixedRegionOneSlopeForVolatility *
            emaVar.toInt256() +
            config.receiveFixedRegionOneSlopeForMeanReversion *
            diffIporIndexEma,
            Constants.D18_INT
        );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma,
        Spread28DaysConfigLibs.BaseSpreadConfig memory config
    ) internal view returns (int256) {
        return
        config.receiveFixedRegionTwoBase +
        IporMath.divisionInt(
            config.receiveFixedRegionTwoSlopeForVolatility *
            emaVar.toInt256() +
            config.receiveFixedRegionTwoSlopeForMeanReversion *
            diffIporIndexEma,
            Constants.D18_INT
        );
    }
}
