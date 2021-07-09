// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";

library DerivativeLogic {

    function calculateInterest(DataTypes.IporDerivative memory derivative, uint256 closingTimestamp, uint ibtPrice) public view returns (DataTypes.IporDerivativeInterest memory) {

        //iFixed = fixed interest rate * notional amount * T / Ty
        require(closingTimestamp >= derivative.startingTimestamp, "Derivative closing timestamp cannot be before derivative starting timestamp");
        uint256 derivativePeriodInSeconds = 0;
        if (closingTimestamp > derivative.endingTimestamp) {
            derivativePeriodInSeconds = derivative.endingTimestamp - derivative.startingTimestamp;
        } else {
            derivativePeriodInSeconds = closingTimestamp - derivative.startingTimestamp;
        }
        uint256 iFixed = derivative.indicator.fixedInterestRate * derivative.notionalAmount;

        //iFloating = IBTQ * IBTPtc - Notional Amount (IBTPtc - interest bearing token price in time when derivative is closed)
        int256 iFloating = int256(derivative.indicator.ibtQuantity * ibtPrice) - int256(derivative.notionalAmount);
        int256 interestDifferenceAmount = derivative.direction == uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating) ? int256(iFixed) - int256(iFloating) : int256(iFloating) - int256(iFixed);

        return DataTypes.IporDerivativeInterest(iFixed, iFloating, interestDifferenceAmount);
    }
}