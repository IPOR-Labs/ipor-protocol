// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../../interfaces/types/IporTypes.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/math/InterestRates.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../security/OwnerManager.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../libraries/RiskManagementLogic.sol";
import "../../../amm/libraries/IporSwapLogic.sol";
import "../../types/AmmTypesBaseV1.sol";

/// @title Core logic for IPOR Swap
library SwapLogicBaseV1 {
    using SafeCast for uint256;
    using SafeCast for int256;
    using InterestRates for uint256;
    using InterestRates for int256;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    /// @notice Calculates core amounts related with swap
    /// @param tenor swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
    /// @param wadTotalAmount total amount represented in 18 decimals
    /// @param leverage swap leverage, represented in 18 decimals
    /// @param wadLiquidationDepositAmount liquidation deposit amount, represented in 18 decimals
    /// @param iporPublicationFeeAmount IPOR publication fee amount, represented in 18 decimals
    /// @param openingFeeRate opening fee rate, represented in 18 decimals
    /// @return collateral collateral amount, represented in 18 decimals
    /// @return notional notional amount, represented in 18 decimals
    /// @return openingFee opening fee amount, represented in 18 decimals
    /// @dev wadTotalAmount = collateral + openingFee + wadLiquidationDepositAmount + iporPublicationFeeAmount
    /// @dev Opening Fee is a multiplication openingFeeRate and notional
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 wadTotalAmount,
        uint256 leverage,
        uint256 wadLiquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) internal pure returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        require(
            wadTotalAmount > wadLiquidationDepositAmount + iporPublicationFeeAmount,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        uint256 availableAmount = wadTotalAmount - wadLiquidationDepositAmount - iporPublicationFeeAmount;

        collateral = IporMath.division(
            availableAmount * 1e18,
            1e18 + IporMath.division(leverage * openingFeeRate * IporSwapLogic.getTenorInDays(tenor), 365 * 1e18)
        );
        notional = IporMath.division(leverage * collateral, 1e18);
        openingFee = availableAmount - collateral;
    }

    function calculatePnl(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        if (swap.direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            pnlValue = calculatePnlPayFixed(swap, closingTimestamp, mdIbtPrice);
        } else if (swap.direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            pnlValue = calculatePnlReceiveFixed(swap, closingTimestamp, mdIbtPrice);
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }
    }

    /// @notice Calculates Profit and Loss (PnL) for a pay fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return pnlValue swap PnL, represented in 18 decimals
    /// @dev Calculated PnL not taken into consideration potential unwinding of the swap.
    function calculatePnlPayFixed(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        pnlValue = IporSwapLogic.normalizePnlValue(
            swap.collateral,
            interestFloating.toInt256() - interestFixed.toInt256()
        );
    }

    /// @notice Calculates Profit and Loss (PnL) for a receive fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return pnlValue swap PnL, represented in 18 decimals
    /// @dev Calculated PnL not taken into consideration potential unwinding of the swap.
    function calculatePnlReceiveFixed(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        pnlValue = IporSwapLogic.normalizePnlValue(
            swap.collateral,
            interestFixed.toInt256() - interestFloating.toInt256()
        );
    }

    /// @notice Calculates the swap unwind PnL value.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// for particular swap at time when swap will be closed by the trader.
    /// @dev Equation for this calculation is:
    /// time - number of seconds left to swap until maturity divided by number of seconds in year
    /// Opposite Leg Fixed Rate - calculated fixed rate of opposite leg used for the virtual swap
    /// @dev If Swap is Pay Fixed Receive Floating then UnwindValue  = Current Swap PnL + Notional * (e^(Opposite Leg Fixed Rate * time) - e^(Swap Fixed Rate * time))
    /// @dev If Swap is Receive Fixed Pay Floating then UnwindValue  = Current Swap PnL + Notional * (e^(Swap Fixed Rate * time) - e^(Opposite Leg Fixed Rate * time))
    function calculateSwapUnwindPnlValue(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) internal pure returns (int256 swapUnwindPnlValue) {
        uint256 endTimestamp = getSwapEndTimestamp(swap);

        require(closingTimestamp <= endTimestamp, AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE);

        uint256 time = (endTimestamp - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp);

        if (swap.direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swapUnwindPnlValue =
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (oppositeLegFixedRate * time).toInt256()
                ) -
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (swap.fixedInterestRate * time).toInt256()
                );
        } else if (swap.direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swapUnwindPnlValue =
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (swap.fixedInterestRate * time).toInt256()
                ) -
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (oppositeLegFixedRate * time).toInt256()
                );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }
    }

    /// @notice Check closable status for Swap given as a parameter.
    /// @param account The account which is closing the swap
    /// @param swapPnlValueToDate The pnl of the swap on a given date
    /// @param closeTimestamp The timestamp of closing
    /// @param swap The swap to be checked
    /// @param poolCfg Pool configuration
    /// @return closableStatus Closable status for Swap.
    /// @return swapUnwindRequired True if swap unwind is required.
    function getClosableStatusForSwap(
        AmmTypesBaseV1.Swap memory swap,
        address account,
        int256 swapPnlValueToDate,
        uint256 closeTimestamp,
        AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (AmmTypes.SwapClosableStatus, bool) {
        if (swap.state != IporTypes.SwapState.ACTIVE) {
            return (AmmTypes.SwapClosableStatus.SWAP_ALREADY_CLOSED, false);
        }

        if (account != OwnerManager.getOwner()) {
            uint256 absPnlValue = IporMath.absoluteValue(swapPnlValueToDate);

            uint256 minPnlValueToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                swap.collateral,
                poolCfg.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            uint256 swapEndTimestamp = getSwapEndTimestamp(swap);

            if (closeTimestamp >= swapEndTimestamp) {
                if (absPnlValue < minPnlValueToCloseBeforeMaturityByCommunity || absPnlValue == swap.collateral) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(poolCfg.asset, account) != true &&
                        account != swap.buyer
                    ) {
                        return (AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE, false);
                    }
                }
            } else {
                uint256 minPnlValueToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    swap.collateral,
                    poolCfg.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPnlValue >= minPnlValueToCloseBeforeMaturityByBuyer &&
                        absPnlValue < minPnlValueToCloseBeforeMaturityByCommunity) || absPnlValue == swap.collateral
                ) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(poolCfg.asset, account) != true &&
                        account != swap.buyer
                    ) {
                        return (AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE, false);
                    }
                }

                if (absPnlValue < minPnlValueToCloseBeforeMaturityByBuyer) {
                    if (account == swap.buyer) {
                        if (swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer > closeTimestamp) {
                            return (AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE, true);
                        }
                    } else {
                        if (
                            swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity > closeTimestamp
                        ) {
                            return (
                                AmmTypes.SwapClosableStatus.SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY,
                                false
                            );
                        }
                    }
                }
            }
        }

        return (AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE, false);
    }

    /// @notice Calculates the swap unwind opening fee amount for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param openingFeeRateCfg opening fee rate taken from Protocol configuration, represented in 18 decimals
    /// @return swapOpeningFeeAmount swap opening fee amount, represented in 18 decimals
    function calculateSwapUnwindOpeningFeeAmount(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) internal pure returns (uint256 swapOpeningFeeAmount) {
        require(closingTimestamp >= swap.openTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        /// @dev 1e36 = 1e18 * 1e18, To achieve result in 18 decimals when there is multiplication of 3 numbers in 18 decimals, we need to divide by 1e36.
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
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (uint256 interestFixed, uint256 interestFloating) {
        require(closingTimestamp >= swap.openTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        interestFixed = IporSwapLogic.calculateInterestFixed(
            swap.notional,
            swap.fixedInterestRate,
            closingTimestamp - swap.openTimestamp
        );

        interestFloating = IporSwapLogic.calculateInterestFloating(swap.ibtQuantity, mdIbtPrice);
    }

    /// @notice Gets swap end timestamp based on swap tenor
    /// @param swap Swap structure
    /// @return swap end timestamp in seconds without 18 decimals
    function getSwapEndTimestamp(AmmTypesBaseV1.Swap memory swap) internal pure returns (uint256) {
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
}
