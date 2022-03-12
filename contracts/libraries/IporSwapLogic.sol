// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./types/DataTypes.sol";
import "./IporMath.sol";
import "./Constants.sol";
import {IporErrors} from "../IporErrors.sol";
import "hardhat/console.sol";

library IporSwapLogic {
    using SafeCast for uint256;

	function calculateSwapAmount(
        uint256 totalAmount,
        uint256 collateralizationFactor,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage
    )
        internal
        pure
        returns (
            uint256 collateral,
            uint256 notional,
            uint256 openingFee
        )
    {
        collateral = IporMath.division(
            (totalAmount - liquidationDepositAmount - iporPublicationFeeAmount) * Constants.D18,
            Constants.D18 + openingFeePercentage
        );
        notional = IporMath.division(collateralizationFactor * collateral, Constants.D18);
        openingFee = IporMath.division(collateral * openingFeePercentage, Constants.D18);
    }

    //@notice for final value divide by Constants.D18* Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(
        uint256 notionalAmount,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) internal pure returns (uint256) {
        return
            notionalAmount *
            Constants.WAD_YEAR_IN_SECONDS +
            notionalAmount *
            swapFixedInterestRate *
            swapPeriodInSeconds;
    }

    //@notice for final value divide by Constants.D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice)
        internal
        pure
        returns (uint256)
    {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when swap is closed)
        return ibtQuantity * ibtCurrentPrice * Constants.YEAR_IN_SECONDS;
    }

    function calculateSwapPayFixedValue(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 quasiIFixed, uint256 quasiIFloating) = calculateQuasiInterest(
            swap,
            closingTimestamp,
            mdIbtPrice
        );

        swapValue = IporMath.divisionInt(
            quasiIFloating.toInt256() - quasiIFixed.toInt256(),
            Constants.WAD_YEAR_IN_SECONDS_INT
        );
    }

    function calculateSwapReceiveFixedValue(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 quasiIFixed, uint256 quasiIFloating) = calculateQuasiInterest(
            swap,
            closingTimestamp,
            mdIbtPrice
        );

        swapValue = IporMath.divisionInt(
            quasiIFixed.toInt256() - quasiIFloating.toInt256(),
            Constants.WAD_YEAR_IN_SECONDS_INT
        );
    }

    function calculateQuasiInterest(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (uint256 quasiIFixed, uint256 quasiIFloating) {
        //iFixed = fixed interest rate * notional amount * T / Ty
        require(
            closingTimestamp >= swap.startingTimestamp,
            IporErrors.MILTON_CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP
        );

        uint256 calculatedPeriodInSeconds = 0;

        //calculated period cannot be longer than whole swap period
        if (closingTimestamp > swap.endingTimestamp) {
            calculatedPeriodInSeconds = swap.endingTimestamp - swap.startingTimestamp;
        } else {
            calculatedPeriodInSeconds = closingTimestamp - swap.startingTimestamp;
        }

        quasiIFixed = calculateQuasiInterestFixed(
            swap.notionalAmount,
            swap.fixedInterestRate,
            calculatedPeriodInSeconds
        );

        quasiIFloating = calculateQuasiInterestFloating(swap.ibtQuantity, mdIbtPrice);
    }
}
