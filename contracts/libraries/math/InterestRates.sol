// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import "../../libraries/Constants.sol";
import "./IporMath.sol";

library InterestRates {
    using SafeCast for uint256;

    /// @notice Adds interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return value with interest, value represented in 18 decimals
    function addContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 interestRatePeriodMultiplication
    ) internal pure returns (uint256) {
        uint256 interestRateYearsMultiplication = IporMath.division(
            interestRatePeriodMultiplication,
            Constants.YEAR_IN_SECONDS
        );
        bytes16 floatValue = _toQuadruplePrecision(value, 1e18);
        bytes16 floatIpm = _toQuadruplePrecision(interestRateYearsMultiplication, 1e18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(floatValue, ABDKMathQuad.exp(floatIpm));
        return _toUint256(valueWithInterest);
    }

    /// @notice Adds interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return value with interest, value represented in 18 decimals
    function addContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
        int256 value,
        int256 interestRatePeriodMultiplication
    ) internal pure returns (int256) {
        int256 interestRateYearsMultiplication = IporMath.divisionInt(
            interestRatePeriodMultiplication,
            Constants.YEAR_IN_SECONDS.toInt256()
        );
        bytes16 floatValue = _toQuadruplePrecisionInt(value, 1e18);
        bytes16 floatIpm = _toQuadruplePrecisionInt(interestRateYearsMultiplication, 1e18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(floatValue, ABDKMathQuad.exp(floatIpm));
        return _toInt256(valueWithInterest);
    }

    /// @notice Calculates interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return interest, value represented in 18 decimals
    function calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 interestRatePeriodMultiplication
    ) internal pure returns (uint256) {
        return
            addContinuousCompoundInterestUsingRatePeriodMultiplication(value, interestRatePeriodMultiplication) - value;
    }

    /// @notice Calculates interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return interest, value represented in 18 decimals
    function calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
        int256 value,
        int256 interestRatePeriodMultiplication
    ) internal pure returns (int256) {
        return
            addContinuousCompoundInterestUsingRatePeriodMultiplicationInt(value, interestRatePeriodMultiplication) -
            value;
    }

    /// @dev Quadruple precision, 128 bits
    function _toQuadruplePrecision(uint256 number, uint256 decimals) private pure returns (bytes16) {
        if (number % decimals > 0) {
            /// @dev during calculation this value is lost in the conversion
            number += 1;
        }
        bytes16 nominator = ABDKMathQuad.fromUInt(number);
        bytes16 denominator = ABDKMathQuad.fromUInt(decimals);
        bytes16 fraction = ABDKMathQuad.div(nominator, denominator);
        return fraction;
    }

    /// @dev Quadruple precision, 128 bits
    function _toQuadruplePrecisionInt(int256 number, int256 decimals) private pure returns (bytes16) {
        if (number % decimals > 0) {
            /// @dev during calculation this value is lost in the conversion
            number += 1;
        }
        bytes16 nominator = ABDKMathQuad.fromInt(number);
        bytes16 denominator = ABDKMathQuad.fromInt(decimals);
        bytes16 fraction = ABDKMathQuad.div(nominator, denominator);
        return fraction;
    }

    function _toUint256(bytes16 value) private pure returns (uint256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(1e18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toUInt(resultD18);
    }

    function _toInt256(bytes16 value) private pure returns (int256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(1e18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toInt(resultD18);
    }
}
