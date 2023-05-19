// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import "../Constants.sol";
import "./IporMath.sol";

library InterestRates {
    uint256 internal constant YEAR_IN_SECONDS = 365 days;

    function addContinuousCompoundInterest(
        uint256 value,
        uint256 interestRate,
        uint256 period
    ) internal pure returns (uint256) {
        bytes16 floatValue = _toQuadruplePrecision(value, Constants.D18);
        bytes16 floatRate = _toQuadruplePrecision(interestRate, Constants.D18);
        bytes16 floatYearPart = _toQuadruplePrecision(period, YEAR_IN_SECONDS);
        bytes16 valueWithInterest = ABDKMathQuad.mul(
            floatValue,
            ABDKMathQuad.exp(ABDKMathQuad.mul(floatRate, floatYearPart))
        );
        return _toUint256(valueWithInterest);
    }

    function addContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 ipm
    ) internal pure returns (uint256) {
        bytes16 floatValue = _toQuadruplePrecision(value, Constants.D18);
        bytes16 floatIpm = _toQuadruplePrecision(ipm, Constants.D18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(
            floatValue,
            ABDKMathQuad.exp(floatIpm)
        );
        return _toUint256(valueWithInterest);
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

    function _toUint256(bytes16 value) private pure returns (uint256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(Constants.D18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toUInt(resultD18);
    }
}
