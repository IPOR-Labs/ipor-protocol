// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../security/IporOwnable.sol";
import "../../interfaces/IMiltonSpreadInternal.sol";

contract MiltonSpreadInternal is IporOwnable, IMiltonSpreadInternal {
    using SafeCast for int256;
    using SafeCast for uint256;

    //@notice Spread Premiums Max Value
    uint256 internal constant _SPREAD_PREMIUMS_MAX_VALUE = 3e15;

    //@notice Part of Spread calculation - Demand Component Kf value - check Whitepaper
    uint256 internal constant _DC_KF_VALUE = 1e13;

    //@notice Part of Spread calculation - Demand Component Lambda value - check Whitepaper
    uint256 internal constant _DC_LAMBDA_VALUE = 1e16;

    //@notice Part of Spread calculation - Demand Component KOmega value - check Whitepaper
    uint256 internal constant _DC_K_OMEGA_VALUE = 5e13;

    //@notice Part of Spread calculation - Demand Component Max Liquidity Redemption Value - check Whitepaper
    uint256 internal constant _DC_MAX_LIQUIDITY_REDEMPTION_VALUE = 1e18;

    int256 internal constant _PAY_FIXED_REGION_ONE_BASE = 1570169440701153;
    int256 internal constant _PAY_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY = 198788881093494850;
    int256 internal constant _PAY_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION = -38331366057144010;

    int256 internal constant _PAY_FIXED_REGION_TWO_BASE = 5957385912947852;
    int256 internal constant _PAY_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY = 422085481190794900;
    int256 internal constant _PAY_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION = -1044585377149331200;

    int256 internal constant _RECEIVE_FIXED_REGION_ONE_BASE = 237699618248428;
    int256 internal constant _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY = 35927957683456455;
    int256 internal constant _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION = 10158530403206013;

    int256 internal constant _RECEIVE_FIXED_REGION_TWO_BASE = -493406136001736;
    int256 internal constant _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY = -2696690872084165600;
    int256 internal constant _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION =
        -923865786926514900;

    function getSpreadPremiumsMaxValue() external pure override returns (uint256) {
        return _getSpreadPremiumsMaxValue();
    }

    function getDCKfValue() external pure override returns (uint256) {
        return _getDCKfValue();
    }

    function getDCLambdaValue() external pure override returns (uint256) {
        return _getDCLambdaValue();
    }

    function getDCKOmegaValue() external pure override returns (uint256) {
        return _getDCKOmegaValue();
    }

    function getDCMaxLiquidityRedemptionValue() external pure override returns (uint256) {
        return _getDCMaxLiquidityRedemptionValue();
    }

    function getPayFixedRegionOneBase() external pure override returns (int256) {
        return _getPayFixedRegionOneBase();
    }

    function getPayFixedRegionOneSlopeForVolatility() external pure override returns (int256) {
        return _getPayFixedRegionOneSlopeForVolatility();
    }

    function getPayFixedRegionOneSlopeForMeanReversion() external pure override returns (int256) {
        return _getPayFixedRegionOneSlopeForMeanReversion();
    }

    function getPayFixedRegionTwoBase() external pure override returns (int256) {
        return _getPayFixedRegionTwoBase();
    }

    function getPayFixedRegionTwoSlopeForVolatility() external pure override returns (int256) {
        return _getPayFixedRegionTwoSlopeForVolatility();
    }

    function getPayFixedRegionTwoSlopeForMeanReversion() external pure override returns (int256) {
        return _getPayFixedRegionTwoSlopeForMeanReversion();
    }

    function getReceiveFixedRegionOneBase() external pure override returns (int256) {
        return _getReceiveFixedRegionOneBase();
    }

    function getReceiveFixedRegionOneSlopeForVolatility() external pure override returns (int256) {
        return _getReceiveFixedRegionOneSlopeForVolatility();
    }

    function getReceiveFixedRegionOneSlopeForMeanReversion()
        external
        pure
        override
        returns (int256)
    {
        return _getReceiveFixedRegionOneSlopeForMeanReversion();
    }

    function getReceiveFixedRegionTwoBase() external pure override returns (int256) {
        return _getReceiveFixedRegionTwoBase();
    }

    function getReceiveFixedRegionTwoSlopeForVolatility() external pure override returns (int256) {
        return _getReceiveFixedRegionTwoSlopeForVolatility();
    }

    function getReceiveFixedRegionTwoSlopeForMeanReversion()
        external
        pure
        override
        returns (int256)
    {
        return _getReceiveFixedRegionTwoSlopeForMeanReversion();
    }

    function _getPayFixedRegionOneBase() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_BASE;
    }

    function _getPayFixedRegionOneSlopeForVolatility() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getPayFixedRegionTwoBase() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_BASE;
    }

    function _getPayFixedRegionTwoSlopeForVolatility() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getReceiveFixedRegionOneBase() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_BASE;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        pure
        virtual
        returns (int256)
    {
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getReceiveFixedRegionTwoBase() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_BASE;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        pure
        virtual
        returns (int256)
    {
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getSpreadPremiumsMaxValue() internal pure virtual returns (uint256) {
        return _SPREAD_PREMIUMS_MAX_VALUE;
    }

    function _getDCKfValue() internal pure virtual returns (uint256) {
        return _DC_KF_VALUE;
    }

    function _getDCLambdaValue() internal pure virtual returns (uint256) {
        return _DC_LAMBDA_VALUE;
    }

    function _getDCKOmegaValue() internal pure virtual returns (uint256) {
        return _DC_K_OMEGA_VALUE;
    }

    function _getDCMaxLiquidityRedemptionValue() internal pure virtual returns (uint256) {
        return _DC_MAX_LIQUIDITY_REDEMPTION_VALUE;
    }

    function _calculateSoapPlus(int256 soap, uint256 swapsBalance) internal pure returns (uint256) {
        if (soap > 0) {
            return IporMath.division(soap.toUint256() * Constants.D18, swapsBalance);
        } else {
            return 0;
        }
    }

    function _calculateAdjustedUtilizationRate(
        uint256 utilizationRateLegWithSwap,
        uint256 utilizationRateLegWithoutSwap,
        uint256 lambda
    ) internal pure returns (uint256) {
        if (utilizationRateLegWithSwap >= utilizationRateLegWithoutSwap) {
            return utilizationRateLegWithSwap;
        } else {
            uint256 imbalanceFactor = IporMath.division(
                lambda * (utilizationRateLegWithoutSwap - utilizationRateLegWithSwap),
                Constants.D18
            );

            if (imbalanceFactor > utilizationRateLegWithSwap) {
                return 0;
            } else {
                return utilizationRateLegWithSwap - imbalanceFactor;
            }
        }
    }

    //@notice Calculates utilization rate including position which is opened
    function _calculateUtilizationRateWithPosition(
        uint256 liquidityPoolBalance,
        uint256 swapsBalance
    ) internal pure returns (uint256) {
        return IporMath.division(swapsBalance * Constants.D18, liquidityPoolBalance);
    }

    //URleg(0)
    function _calculateUtilizationRateWithoutSwap(
        uint256 liquidityPoolBalance,
        uint256 swapsBalance
    ) internal pure returns (uint256) {
        return IporMath.division(swapsBalance * Constants.D18, liquidityPoolBalance);
    }
}
