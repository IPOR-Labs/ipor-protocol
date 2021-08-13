// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";
import "./AmmMath.sol";
import "./Constants.sol";

library DerivativeLogic {

    function calculateInterestFixed(uint256 mdNotionalAmount, uint256 mdDerivativeFixedInterestRate, uint256 derivativePeriodInSeconds) public pure returns (uint256) {
        return mdNotionalAmount + AmmMath.division(mdNotionalAmount * mdDerivativeFixedInterestRate * derivativePeriodInSeconds, Constants.MD_YEAR_IN_SECONDS);
    }

    function calculateInterestFloating(uint256 mdIbtQuantity, uint256 mdIbtCurrentPrice) public pure returns (uint256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when derivative is closed)
        return AmmMath.division(mdIbtQuantity * mdIbtCurrentPrice, Constants.MD);
    }

    function calculateInterest(
        DataTypes.IporDerivative memory derivative,
        uint256 closingTimestamp,
        uint256 mdIbtPrice) public pure returns (DataTypes.IporDerivativeInterest memory) {

        //iFixed = fixed interest rate * notional amount * T / Ty
        require(closingTimestamp >= derivative.startingTimestamp, "Derivative closing timestamp cannot be before derivative starting timestamp");

        uint256 calculatedPeriodInSeconds = 0;

        //calculated period cannot be longer than whole derivative period
        if (closingTimestamp > derivative.endingTimestamp) {
            calculatedPeriodInSeconds = derivative.endingTimestamp - derivative.startingTimestamp;
        } else {
            calculatedPeriodInSeconds = closingTimestamp - derivative.startingTimestamp;
        }

        uint256 iFixed = calculateInterestFixed(derivative.notionalAmount, derivative.indicator.fixedInterestRate, calculatedPeriodInSeconds);
        uint256 iFloating = calculateInterestFloating(derivative.indicator.ibtQuantity, mdIbtPrice);

        int256 interestDifferenceAmount = uint8(derivative.direction) == uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
        ? int256(iFloating) - int256(iFixed) : int256(iFixed) - int256(iFloating);

        return DataTypes.IporDerivativeInterest(iFixed, iFloating, interestDifferenceAmount);
    }
}