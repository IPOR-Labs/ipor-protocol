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

    int256 internal constant _B1 = -8260047328466268;
    int256 internal constant _B2 = -9721941081703882;
    int256 internal constant _V1 = 47294930726988593;
    int256 internal constant _V2 = 8792990351805524;
    int256 internal constant _M1 = -9721941081703882;
    int256 internal constant _M2 = -3996501128463404;

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

    function getB1() external pure override returns (int256) {
        return _getB1();
    }

    function getB2() external pure override returns (int256) {
        return _getB2();
    }

    function getV1() external pure override returns (int256) {
        return _getV1();
    }

    function getV2() external pure override returns (int256) {
        return _getV2();
    }

    function getM1() external pure override returns (int256) {
        return _getM1();
    }

    function getM2() external pure override returns (int256) {
        return _getM2();
    }

    function _getB1() internal pure virtual returns (int256) {
        return _B1;
    }

    function _getB2() internal pure virtual returns (int256) {
        return _B2;
    }

    function _getV1() internal pure virtual returns (int256) {
        return _V1;
    }

    function _getV2() internal pure virtual returns (int256) {
        return _V2;
    }

    function _getM1() internal pure virtual returns (int256) {
        return _M1;
    }

    function _getM2() internal pure virtual returns (int256) {
        return _M2;
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
