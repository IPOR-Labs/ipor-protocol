// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/math/InterestRates.sol";
import "../../libraries/errors/AmmErrors.sol";

/// @title Core logic for IPOR Swap
library IporSwapLogic {
    using SafeCast for uint256;
    using SafeCast for int256;
    using InterestRates for uint256;
    using InterestRates for int256;

    /// @param tenor swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
    /// @param wadTotalAmount total amount represented in 18 decimals
    /// @param leverage swap leverage, represented in 18 decimals
    /// @param wadLiquidationDepositAmount liquidation deposit amount, represented in 18 decimals
    /// @param iporPublicationFeeAmount IPOR publication fee amount, represented in 18 decimals
    /// @param openingFeeRate opening fee rate, represented in 18 decimals
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 wadTotalAmount,
        uint256 leverage,
        uint256 wadLiquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) internal pure returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        uint256 availableAmount = wadTotalAmount - wadLiquidationDepositAmount - iporPublicationFeeAmount;

        collateral = IporMath.division(
            availableAmount * 1e18,
            1e18 + IporMath.division(leverage * openingFeeRate * getTenorInDays(tenor), 365 * 1e18)
        );
        notional = IporMath.division(leverage * collateral, 1e18);
        openingFee = availableAmount - collateral;
    }

    /// @notice Calculates payoff for a pay fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return swapValue swap payoff, represented in 18 decimals
    /// @dev Calculated payoff not taken into consideration potential unwinding of the swap.
    function calculatePayoffPayFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        swapValue = normalizeSwapValue(swap.collateral, interestFloating.toInt256() - interestFixed.toInt256());
    }

    /// @notice Calculates payoff for a receive fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return swapValue swap payoff, represented in 18 decimals
    /// @dev Calculated payoff not taken into consideration potential unwinding of the swap.
    function calculatePayoffReceiveFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        swapValue = normalizeSwapValue(swap.collateral, interestFixed.toInt256() - interestFloating.toInt256());
    }

    /// @notice Calculates the swap unwind value, virtual hedging position needed when swaps is closed before the maturity day.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param swapPayoffToDate swap payoff to date, represented in 18 decimals, this represents value of payoff
    /// for particular swap at time when swap will be closed by the trader.
    /// @dev Equation for this calculation is:
    /// time - number of seconds left to swap until maturity divided by number of seconds in year
    /// Opposite Leg Fixed Rate - calculated fixed rate of opposite leg used for the virtual swap
    /// @dev UnwindValue   = Current Swap Payoff + Notional * (e^(Opposite Leg Fixed Rate * time) - e^(Swap Fixed Rate * time))
    function calculateSwapUnwindAmount(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        int256 swapPayoffToDate,
        uint256 oppositeLegFixedRate
    ) internal pure returns (int256 swapUnwindAmount) {
        uint256 endTimestamp = getSwapEndTimestamp(swap);

        require(closingTimestamp <= endTimestamp, AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE);

        uint256 time = (endTimestamp - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp);

        swapUnwindAmount =
            swapPayoffToDate +
            swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                (oppositeLegFixedRate * time).toInt256()
            ) -
            swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                (swap.fixedInterestRate * time).toInt256()
            );
    }

    /// @notice Calculates the swap unwind opening fee amount for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param openingFeeRateCfg opening fee rate taken from Protocol configuration, represented in 18 decimals
    /// @return swapOpeningFeeAmount swap opening fee amount, represented in 18 decimals
    function calculateSwapUnwindOpeningFeeAmount(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) internal pure returns (uint256 swapOpeningFeeAmount) {
        swapOpeningFeeAmount = IporMath.division(
            swap.notional *
                openingFeeRateCfg *
                IporMath.division(
                    ((getSwapEndTimestamp(swap) - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp)) * 1e18,
                    365 days
                ),
            1e36
        );
    }

    /// @notice Calculates interest including continuous capitalization for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return interestFixed fixed interest chunk, represented in 18 decimals
    /// @return interestFloating floating interest chunk, represented in 18 decimals
    function calculateInterest(
        AmmTypes.Swap memory swap,
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

    /// @notice Calculates fixed interest chunk including continuous capitalization for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param notional swap notional, represented in 18 decimals
    /// @param swapFixedInterestRate fixed interest rate on a swap, represented in 18 decimals
    /// @param swapPeriodInSeconds swap period in seconds
    /// @return interestFixed fixed interest chunk, represented in 18 decimals
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

    /// @notice Calculates floating interest chunk for a given ibt quantity and IBT current price
    /// @param ibtQuantity IBT quantity, represented in 18 decimals
    /// @param ibtCurrentPrice IBT price from IporOracle, represented in 18 decimals
    /// @return interestFloating floating interest chunk, represented in 18 decimals
    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice) internal pure returns (uint256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when swap is closed)
        return IporMath.division(ibtQuantity * ibtCurrentPrice, 1e18);
    }

    /// @notice Normalizes swap value to collateral value. Absolute value Swap payoff can't be higher than collateral.
    /// @param collateral collateral value, represented in 18 decimals
    /// @param swapPayoff swap payoff, represented in 18 decimals
    function normalizeSwapValue(uint256 collateral, int256 swapPayoff) internal pure returns (int256) {
        int256 intCollateral = collateral.toInt256();

        if (swapPayoff > 0) {
            if (swapPayoff < intCollateral) {
                return swapPayoff;
            } else {
                return intCollateral;
            }
        } else {
            if (swapPayoff < -intCollateral) {
                return -intCollateral;
            } else {
                return swapPayoff;
            }
        }
    }

    /// @notice Gets swap end timestamp based on swap tenor
    /// @param swap Swap structure
    /// @return swap end timestamp in seconds without 18 decimals
    function getSwapEndTimestamp(AmmTypes.Swap memory swap) internal pure returns (uint256) {
        if (swap.tenor == IporTypes.SwapTenor.DAYS_28) {
            return swap.openTimestamp + 28 days;
        } else if (swap.tenor == IporTypes.SwapTenor.DAYS_60) {
            return swap.openTimestamp + 60 days;
        } else if (swap.tenor == IporTypes.SwapTenor.DAYS_90) {
            return swap.openTimestamp + 90 days;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }

    /// @notice Gets swap tenor in seconds
    /// @param tenor Swap tenor
    /// @return swap tenor in seconds
    function getTenorInSeconds(IporTypes.SwapTenor tenor) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return 28 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return 60 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return 90 days;
        }
        revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
    }

    /// @notice Gets swap tenor in days
    /// @param tenor Swap tenor
    /// @return swap tenor in days
    function getTenorInDays(IporTypes.SwapTenor tenor) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return 28;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return 60;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return 90;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }

    /// @notice Splits opening fee amount into liquidity pool and treasury portions
    /// @param openingFeeAmount opening fee amount, represented in 18 decimals
    /// @param openingFeeForTreasurePortionRate opening fee for treasury portion rate taken from Protocol configuration, represented in 18 decimals
    /// @return liquidityPoolAmount liquidity pool portion of opening fee, represented in 18 decimals
    /// @return treasuryAmount treasury portion of opening fee, represented in 18 decimals
    function splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePortionRate
    ) internal pure returns (uint256 liquidityPoolAmount, uint256 treasuryAmount) {
        treasuryAmount = IporMath.division(openingFeeAmount * openingFeeForTreasurePortionRate, 1e18);
        liquidityPoolAmount = openingFeeAmount - treasuryAmount;
    }
}
