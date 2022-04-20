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

    int256 internal constant _PAY_FIXED_REGION_ONE_BASE = 157019226449085840;
    int256 internal constant _PAY_FIXED_REGION_ONE_SLOPE_FACTOR_ONE = 19995379670799840000;
    int256 internal constant _PAY_FIXED_REGION_ONE_SLOPE_FACTOR_TWO = -3841736186289212000;

    int256 internal constant _PAY_FIXED_REGION_TWO_BASE = 595866254143749400;
    int256 internal constant _PAY_FIXED_REGION_TWO_SLOPE_FACTOR_ONE = 42133363586198140000;
    int256 internal constant _PAY_FIXED_REGION_TWO_SLOPE_FACTOR_TWO = -104460848714451840000;

    int256 internal constant _RECEIVE_FIXED_REGION_ONE_BASE = 23984087324369713;
    int256 internal constant _RECEIVE_FIXED_REGION_ONE_SLOPE_FACTOR_ONE = 3528665170882902700;
    int256 internal constant _RECEIVE_FIXED_REGION_ONE_SLOPE_FACTOR_TWO = 1018371437526577500;

    int256 internal constant _RECEIVE_FIXED_REGION_TWO_BASE = -49374213950104766;
    int256 internal constant _RECEIVE_FIXED_REGION_TWO_SLOPE_FACTOR_ONE = -269622133795293730000;
    int256 internal constant _RECEIVE_FIXED_REGION_TWO_SLOPE_FACTOR_TWO = -92391136608777590000;

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

    function getPayFixedRegionOneSlopeFactorOne() external pure override returns (int256) {
        return _getPayFixedRegionOneSlopeFactorOne();
    }

    function getPayFixedRegionOneSlopeFactorTwo() external pure override returns (int256) {
        return _getPayFixedRegionOneSlopeFactorTwo();
    }

    function getPayFixedRegionTwoBase() external pure override returns (int256) {
        return _getPayFixedRegionTwoBase();
    }

    function getPayFixedRegionTwoSlopeFactorOne() external pure override returns (int256) {
        return _getPayFixedRegionTwoSlopeFactorOne();
    }

    function getPayFixedRegionTwoSlopeFactorTwo() external pure override returns (int256) {
        return _getPayFixedRegionTwoSlopeFactorTwo();
    }

    function getReceiveFixedRegionOneBase() external pure override returns (int256) {
        return _getReceiveFixedRegionOneBase();
    }

    function getReceiveFixedRegionOneSlopeFactorOne() external pure override returns (int256) {
        return _getReceiveFixedRegionOneSlopeFactorOne();
    }

    function getReceiveFixedRegionOneSlopeFactorTwo() external pure override returns (int256) {
        return _getReceiveFixedRegionOneSlopeFactorTwo();
    }

    function getReceiveFixedRegionTwoBase() external pure override returns (int256) {
        return _getReceiveFixedRegionTwoBase();
    }

    function getReceiveFixedRegionTwoSlopeFactorOne() external pure override returns (int256) {
        return _getReceiveFixedRegionTwoSlopeFactorOne();
    }

    function getReceiveFixedRegionTwoSlopeFactorTwo() external pure override returns (int256) {
        return _getReceiveFixedRegionTwoSlopeFactorTwo();
    }

    function _getPayFixedRegionOneBase() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_BASE;
    }

    function _getPayFixedRegionOneSlopeFactorOne() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_SLOPE_FACTOR_ONE;
    }

    function _getPayFixedRegionOneSlopeFactorTwo() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_SLOPE_FACTOR_TWO;
    }

    function _getPayFixedRegionTwoBase() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_BASE;
    }

    function _getPayFixedRegionTwoSlopeFactorOne() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_SLOPE_FACTOR_ONE;
    }

    function _getPayFixedRegionTwoSlopeFactorTwo() internal pure virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_SLOPE_FACTOR_TWO;
    }

    function _getReceiveFixedRegionOneBase() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_BASE;
    }

    function _getReceiveFixedRegionOneSlopeFactorOne() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FACTOR_ONE;
    }

    function _getReceiveFixedRegionOneSlopeFactorTwo() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FACTOR_TWO;
    }

    function _getReceiveFixedRegionTwoBase() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_BASE;
    }

    function _getReceiveFixedRegionTwoSlopeFactorOne() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FACTOR_ONE;
    }

    function _getReceiveFixedRegionTwoSlopeFactorTwo() internal pure virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FACTOR_TWO;
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
