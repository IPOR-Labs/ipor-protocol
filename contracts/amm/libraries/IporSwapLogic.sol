// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/AmmErrors.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/math/InterestRates.sol";
import "../../interfaces/types/AmmTypes.sol";

library IporSwapLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    /// @param duration swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
    /// @param totalAmount total amount represented in 18 decimals
    /// @param leverage swap leverage, represented in 18 decimals
    /// @param liquidationDepositAmount liquidation deposit amount, represented in 18 decimals
    /// @param iporPublicationFeeAmount IPOR publication fee amount, represented in 18 decimals
    /// @param openingFeeRate opening fee rate, represented in 18 decimals
    function calculateSwapAmount(
        AmmTypes.SwapDuration duration,
        uint256 totalAmount,
        uint256 leverage,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    )
        internal
        pure
        returns (
            uint256 collateral,
            uint256 notional,
            uint256 openingFee
        )
    {
        uint256 availableAmount = totalAmount - liquidationDepositAmount - iporPublicationFeeAmount;

        collateral = IporMath.division(
            availableAmount * Constants.D18,
            Constants.D18 +
                IporMath.division(leverage * openingFeeRate * getTimeToMaturityInDays(duration), 365 * Constants.D18)
        );
        notional = IporMath.division(leverage * collateral, Constants.D18);
        openingFee = availableAmount - collateral;
    }

    function getTimeToMaturityInDays(AmmTypes.SwapDuration duration) internal pure returns (uint256) {
        if (duration == AmmTypes.SwapDuration.DAYS_28) {
            return 28;
        } else if (duration == AmmTypes.SwapDuration.DAYS_60) {
            return 60;
        } else if (duration == AmmTypes.SwapDuration.DAYS_90) {
            return 90;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_DURATION);
        }
    }

    function calculatePayoffPayFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        swapValue = _normalizeSwapValue(swap.collateral, interestFloating.toInt256() - interestFixed.toInt256());
    }

    function calculatePayoffReceiveFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        swapValue = _normalizeSwapValue(swap.collateral, interestFixed.toInt256() - interestFloating.toInt256());
    }

    function calculateSwapUnwindValue(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        int256 swapPayoffToDate,
        uint256 oppositeLegFixedRate,
        uint256 openingFeeRateForSwapUnwind
    ) internal pure returns (int256 swapUnwindValue) {
        uint256 endTimestamp = calculateSwapMaturity(swap);
        require(closingTimestamp <= endTimestamp, AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE);

        swapUnwindValue =
            swapPayoffToDate +
                swap.notional.toInt256() *
                    (oppositeLegFixedRate.toInt256() - swap.fixedInterestRate.toInt256()) *
                    ((endTimestamp - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp)).toInt256() -
            openingFeeRateForSwapUnwind.toInt256();
    }

    function calculateInterest(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (uint256 interestFixed, uint256 interestFloating) {
        require(closingTimestamp >= swap.openTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        interestFixed = calculateInterestFixed(
            swap.notional,
            swap.fixedInterestRate,
            closingTimestamp - swap.openTimestamp
        );

        interestFloating = calculateInterestFloating(swap.ibtQuantity, mdIbtPrice);
    }

    function calculateInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) internal pure returns (uint256) {
        return
            notional.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                swapFixedInterestRate * swapPeriodInSeconds
            );
    }

    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice) internal pure returns (uint256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when swap is closed)
        return IporMath.division(ibtQuantity * ibtCurrentPrice, Constants.D18);
    }

    function _normalizeSwapValue(uint256 collateral, int256 swapValue) private pure returns (int256) {
        int256 intCollateral = collateral.toInt256();

        if (swapValue > 0) {
            if (swapValue < intCollateral) {
                return swapValue;
            } else {
                return intCollateral;
            }
        } else {
            if (swapValue < -intCollateral) {
                return -intCollateral;
            } else {
                return swapValue;
            }
        }
    }

    function calculateSwapMaturity(IporTypes.IporSwapMemory memory swap) internal pure returns (uint256) {
        if (swap.duration == 0) {
            return swap.openTimestamp + 28 days;
        } else if (swap.duration == 1) {
            return swap.openTimestamp + 60 days;
        } else if (swap.duration == 2) {
            return swap.openTimestamp + 90 days;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_DURATION);
        }
    }
}
