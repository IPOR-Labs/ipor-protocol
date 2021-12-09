// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/DataTypes.sol";
import "./AmmMath.sol";
import "./Constants.sol";
import { Errors } from "../Errors.sol";

library DerivativeLogic {
    //@notice for final value divide by multiplicator* Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(
        uint256 notionalAmount,
        uint256 derivativeFixedInterestRate,
        uint256 derivativePeriodInSeconds
    ) internal pure returns (uint256) {
        return
            notionalAmount *
            Constants.WAD_YEAR_IN_SECONDS +
            notionalAmount *
            derivativeFixedInterestRate *
            derivativePeriodInSeconds;
    }

    //@notice for final value divide by multiplicator * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFloating(
        uint256 ibtQuantity,
        uint256 ibtCurrentPrice
    ) internal pure returns (uint256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when derivative is closed)
        return ibtQuantity * ibtCurrentPrice * Constants.YEAR_IN_SECONDS;
    }

    function calculateInterest(
        DataTypes.IporDerivative memory derivative,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (DataTypes.IporDerivativeInterest memory) {
        //iFixed = fixed interest rate * notional amount * T / Ty
        require(
            closingTimestamp >= derivative.startingTimestamp,
            Errors.MILTON_CLOSING_TIMESTAMP_LOWER_THAN_DERIVATIVE_OPEN_TIMESTAMP
        );

        uint256 calculatedPeriodInSeconds = 0;

        //calculated period cannot be longer than whole derivative period
        if (closingTimestamp > derivative.endingTimestamp) {
            calculatedPeriodInSeconds =
                derivative.endingTimestamp -
                derivative.startingTimestamp;
        } else {
            calculatedPeriodInSeconds =
                closingTimestamp -
                derivative.startingTimestamp;
        }
        //TODO: use SafeCast from openzeppelin
        uint256 quasiIFixed = calculateQuasiInterestFixed(
            derivative.notionalAmount,
            derivative.indicator.fixedInterestRate,
            calculatedPeriodInSeconds
        );
        uint256 quasiIFloating = calculateQuasiInterestFloating(
            derivative.indicator.ibtQuantity,
            mdIbtPrice
        );

        int256 positionValue = AmmMath.divisionInt(
            uint8(derivative.direction) ==
                uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
                ? int256(quasiIFloating) - int256(quasiIFixed)
                : int256(quasiIFixed) - int256(quasiIFloating),
            Constants.WAD_YEAR_IN_SECONDS_INT
        );

        return
            DataTypes.IporDerivativeInterest(
                quasiIFixed,
                quasiIFloating,
                positionValue
            );
    }
}
