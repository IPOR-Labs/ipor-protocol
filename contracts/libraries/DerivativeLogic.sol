// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";
import "./AmmMath.sol";
import "./Constants.sol";
import {Errors} from '../Errors.sol';

library DerivativeLogic {

    //@notice for final value divide by Constants.MD_YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(uint256 mdNotionalAmount, uint256 mdDerivativeFixedInterestRate, uint256 derivativePeriodInSeconds) public pure returns (uint256) {
        return mdNotionalAmount * Constants.MD_YEAR_IN_SECONDS + mdNotionalAmount * mdDerivativeFixedInterestRate * derivativePeriodInSeconds;
    }

    //@notice for final value divide by Constants.MD_YEAR_IN_SECONDS
    function calculateQuasiInterestFloating(uint256 mdIbtQuantity, uint256 mdIbtCurrentPrice) public pure returns (uint256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when derivative is closed)
        return mdIbtQuantity * mdIbtCurrentPrice * Constants.YEAR_IN_SECONDS;
    }

    function calculateInterest(
        DataTypes.IporDerivative memory derivative,
        uint256 closingTimestamp,
        uint256 mdIbtPrice) public pure returns (DataTypes.IporDerivativeInterest memory) {

        //iFixed = fixed interest rate * notional amount * T / Ty
        require(closingTimestamp >= derivative.startingTimestamp, Errors.MILTON_CLOSING_TIMESTAMP_LOWER_THAN_DERIVATIVE_OPEN_TIMESTAMP);

        uint256 calculatedPeriodInSeconds = 0;

        //calculated period cannot be longer than whole derivative period
        if (closingTimestamp > derivative.endingTimestamp) {
            calculatedPeriodInSeconds = derivative.endingTimestamp - derivative.startingTimestamp;
        } else {
            calculatedPeriodInSeconds = closingTimestamp - derivative.startingTimestamp;
        }

        uint256 quasiIFixed = calculateQuasiInterestFixed(derivative.notionalAmount, derivative.indicator.fixedInterestRate, calculatedPeriodInSeconds);
        uint256 quasiIFloating = calculateQuasiInterestFloating(derivative.indicator.ibtQuantity, mdIbtPrice);

        int256 interestDifferenceAmount = AmmMath.divisionInt(uint8(derivative.direction) == uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
            ? int256(quasiIFloating) - int256(quasiIFixed) : int256(quasiIFixed) - int256(quasiIFloating), int256(Constants.MD_YEAR_IN_SECONDS));

        return DataTypes.IporDerivativeInterest(quasiIFixed, quasiIFloating, interestDifferenceAmount);
    }
}