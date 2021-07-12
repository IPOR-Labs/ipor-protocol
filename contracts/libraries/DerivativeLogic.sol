// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";
import "./AmmMath.sol";

library DerivativeLogic {

    uint256 constant YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;

    function calculateInterestFixed(uint256 notionalAmount, uint256 derivativeFixedInterestRate, uint256 derivativePeriodInSeconds) public pure returns (uint256) {
        return notionalAmount + (notionalAmount * derivativeFixedInterestRate * derivativePeriodInSeconds / YEAR_IN_SECONDS) / AmmMath.LAS_VEGAS_DECIMALS_FACTOR;
    }

    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice) public pure returns (int256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when derivative is closed)
        return int256(ibtQuantity * ibtCurrentPrice / AmmMath.LAS_VEGAS_DECIMALS_FACTOR);
    }

    function calculateInterest(DataTypes.IporDerivative memory derivative, uint256 closingTimestamp, uint256 ibtPrice) public pure returns (DataTypes.IporDerivativeInterest memory) {

        //iFixed = fixed interest rate * notional amount * T / Ty
        require(closingTimestamp >= derivative.startingTimestamp, "Derivative closing timestamp cannot be before derivative starting timestamp");
        uint256 derivativePeriodInSeconds = 0;
        if (closingTimestamp > derivative.endingTimestamp) {
            derivativePeriodInSeconds = derivative.endingTimestamp - derivative.startingTimestamp;
        } else {
            derivativePeriodInSeconds = closingTimestamp - derivative.startingTimestamp;
        }

        uint256 iFixed = calculateInterestFixed(derivative.notionalAmount, derivative.indicator.fixedInterestRate, derivativePeriodInSeconds);
        int256 iFloating = calculateInterestFloating(derivative.indicator.ibtQuantity, ibtPrice);

        int256 interestDifferenceAmount = derivative.direction == uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
        ? int256(iFloating) - int256(iFixed) : int256(iFixed) - int256(iFloating);

        return DataTypes.IporDerivativeInterest(iFixed, iFloating, interestDifferenceAmount);
    }
}