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

    //@notice Part of Spread calculation - At Par Component - Volatility Kvol value - check Whitepaper
    uint256 internal constant _AT_PAR_COMPONENT_K_VOL_VALUE = 0;

    //@notice Part of Spread calculation - At Par Component - Historical Deviation Khist value - check Whitepaper
    uint256 internal constant _AT_PAR_COMPONENT_K_HIST_VALUE = 3e14;

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

    function getAtParComponentKVolValue() external pure override returns (uint256) {
        return _getAtParComponentKVolValue();
    }

    function getAtParComponentKHistValue() external pure override returns (uint256) {
        return _getAtParComponentKHistValue();
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

    function _getAtParComponentKVolValue() internal pure virtual returns (uint256) {
        return _AT_PAR_COMPONENT_K_VOL_VALUE;
    }

    function _getAtParComponentKHistValue() internal pure virtual returns (uint256) {
        return _AT_PAR_COMPONENT_K_HIST_VALUE;
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

    function _calculateHistoricalDeviationPayFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage < iporIndexValue) {
            return 0;
        } else {
            uint256 mu = IporMath.absoluteValue(
                exponentialMovingAverage.toInt256() - iporIndexValue.toInt256()
            );
            if (mu == Constants.D18) {
                return maxSpreadValue;
            } else {
                return IporMath.division(kHist * Constants.D18, Constants.D18 - mu);
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
            uint256 mu = IporMath.absoluteValue(
                exponentialMovingAverage.toInt256() - iporIndexValue.toInt256()
            );
            if (mu >= Constants.D18) {
                return maxSpreadValue;
            } else {
                return IporMath.division(kHist * Constants.D18, Constants.D18 - mu);
            }
        }
    }
}
