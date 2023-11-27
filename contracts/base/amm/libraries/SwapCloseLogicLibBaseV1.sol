// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../interfaces/IAmmStorageBaseV1.sol";
import "../../interfaces/IAmmTreasuryBaseV1.sol";
import "../../interfaces/ISpreadBaseV1.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../types/AmmTypesBaseV1.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../security/OwnerManager.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../libraries/math/InterestRates.sol";
import "../../../libraries/RiskManagementLogic.sol";
import "./SwapLogicBaseV1.sol";

library SwapCloseLogicLibBaseV1 {
    using SafeCast for uint256;
    using SafeCast for int256;
    using InterestRates for uint256;
    using InterestRates for int256;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    function calculateSwapUnwindPnlValueNormalized(
        AmmTypesBaseV1.UnwindParams memory unwindParams,
        AmmTypes.SwapDirection oppositeDirection,
        AmmTypes.OpenSwapRiskIndicators memory oppositeRiskIndicators
    ) internal view returns (int256) {
        AmmTypesBaseV1.AmmBalanceForOpenSwap memory balance = IAmmStorageBaseV1(unwindParams.ammStorage)
            .getBalancesForOpenSwap();
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(unwindParams.ammTreasury).getLiquidityPoolBalance();

        return
            SwapLogicBaseV1.normalizePnlValue(
                unwindParams.swap.collateral,
                calculateSwapUnwindPnlValue(
                    unwindParams.swap,
                    unwindParams.closeTimestamp,
                    ISpreadBaseV1(unwindParams.spread).calculateOfferedRate(
                        oppositeDirection,
                        ISpreadBaseV1.SpreadInputs({
                            asset: unwindParams.asset,
                            swapNotional: unwindParams.swap.notional,
                            demandSpreadFactor: oppositeRiskIndicators.demandSpreadFactor,
                            baseSpreadPerLeg: oppositeRiskIndicators.baseSpreadPerLeg,
                            totalCollateralPayFixed: balance.totalCollateralPayFixed,
                            totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                            liquidityPoolBalance: liquidityPoolBalance,
                            iporIndexValue: unwindParams.indexValue,
                            fixedRateCapPerLeg: oppositeRiskIndicators.fixedRateCapPerLeg,
                            tenor: unwindParams.swap.tenor
                        })
                    )
                )
            );
    }

    /// @notice Calculate swap unwind when unwind is required.
    /// @param unwindParams unwind parameters required to calculate swap unwind pnl value.
    /// @return swapUnwindPnlValue swap unwind PnL value
    /// @return swapUnwindFeeAmount swap unwind opening fee amount, sum of swapUnwindFeeLPAmount and swapUnwindFeeTreasuryAmount
    /// @return swapUnwindFeeLPAmount swap unwind opening fee LP amount
    /// @return swapUnwindFeeTreasuryAmount swap unwind opening fee treasury amount
    /// @return swapPnlValue swap PnL value includes swap PnL to date, swap unwind PnL value, this value NOT INCLUDE swap unwind fee amount.
    function calculateSwapUnwindWhenUnwindRequired(
        AmmTypesBaseV1.UnwindParams memory unwindParams
    )
        internal
        view
        returns (
            int256 swapUnwindPnlValue,
            uint256 swapUnwindFeeAmount,
            uint256 swapUnwindFeeLPAmount,
            uint256 swapUnwindFeeTreasuryAmount,
            int256 swapPnlValue
        )
    {
        AmmTypes.OpenSwapRiskIndicators memory oppositeRiskIndicators;

        if (unwindParams.swap.direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            oppositeRiskIndicators = unwindParams.riskIndicatorsInputs.receiveFixed.verify(
                unwindParams.asset,
                uint256(unwindParams.swap.tenor),
                uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                unwindParams.messageSigner
            );
            /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
            swapUnwindPnlValue = calculateSwapUnwindPnlValueNormalized(
                unwindParams,
                AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
                oppositeRiskIndicators
            );
        } else if (unwindParams.swap.direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            oppositeRiskIndicators = unwindParams.riskIndicatorsInputs.payFixed.verify(
                unwindParams.asset,
                uint256(unwindParams.swap.tenor),
                uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                unwindParams.messageSigner
            );
            /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
            swapUnwindPnlValue = calculateSwapUnwindPnlValueNormalized(
                unwindParams,
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                oppositeRiskIndicators
            );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        swapPnlValue = SwapLogicBaseV1.normalizePnlValue(
            unwindParams.swap.collateral,
            unwindParams.swapPnlValueToDate + swapUnwindPnlValue
        );

        /// @dev swap unwind fee amount is independent of the swap unwind pnl value, takes into consideration notional.
        swapUnwindFeeAmount = calculateSwapUnwindOpeningFeeAmount(
            unwindParams.swap,
            unwindParams.closeTimestamp,
            unwindParams.unwindingFeeRate
        );

        require(
            unwindParams.swap.collateral.toInt256() + swapPnlValue > swapUnwindFeeAmount.toInt256(),
            AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP
        );

        (swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount) = SwapLogicBaseV1.splitOpeningFeeAmount(
            swapUnwindFeeAmount,
            unwindParams.unwindingFeeTreasuryPortionRate
        );

        swapPnlValue = unwindParams.swapPnlValueToDate + swapUnwindPnlValue;
    }

    function getClosableStatusForSwap(
        AmmTypesBaseV1.ClosableSwapInput memory closableSwapInput
    ) internal view returns (AmmTypes.SwapClosableStatus, bool) {
        if (closableSwapInput.swapState != IporTypes.SwapState.ACTIVE) {
            return (AmmTypes.SwapClosableStatus.SWAP_ALREADY_CLOSED, false);
        }

        if (closableSwapInput.account != OwnerManager.getOwner()) {
            uint256 absPnlValue = IporMath.absoluteValue(closableSwapInput.swapPnlValueToDate);

            uint256 minPnlValueToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                closableSwapInput.swapCollateral,
                closableSwapInput.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            uint256 swapEndTimestamp = getSwapEndTimestamp(
                closableSwapInput.swapOpenTimestamp,
                closableSwapInput.swapTenor
            );

            if (closableSwapInput.closeTimestamp >= swapEndTimestamp) {
                if (
                    absPnlValue < minPnlValueToCloseBeforeMaturityByCommunity ||
                    absPnlValue == closableSwapInput.swapCollateral
                ) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(closableSwapInput.asset, closableSwapInput.account) !=
                        true &&
                        closableSwapInput.account != closableSwapInput.swapBuyer
                    ) {
                        return (AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE, false);
                    }
                }
            } else {
                uint256 minPnlValueToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    closableSwapInput.swapCollateral,
                    closableSwapInput.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPnlValue >= minPnlValueToCloseBeforeMaturityByBuyer &&
                        absPnlValue < minPnlValueToCloseBeforeMaturityByCommunity) ||
                    absPnlValue == closableSwapInput.swapCollateral
                ) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(closableSwapInput.asset, closableSwapInput.account) !=
                        true &&
                        closableSwapInput.account != closableSwapInput.swapBuyer
                    ) {
                        return (AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE, false);
                    }
                }

                if (absPnlValue < minPnlValueToCloseBeforeMaturityByBuyer) {
                    if (closableSwapInput.account == closableSwapInput.swapBuyer) {
                        if (
                            swapEndTimestamp - closableSwapInput.timeBeforeMaturityAllowedToCloseSwapByBuyer >
                            closableSwapInput.closeTimestamp
                        ) {
                            if (
                                block.timestamp - closableSwapInput.swapOpenTimestamp <=
                                closableSwapInput.timeAfterOpenAllowedToCloseSwapWithUnwinding
                            ) {
                                return (
                                    AmmTypes.SwapClosableStatus.SWAP_CANNOT_CLOSE_WITH_UNWIND_ACTION_IS_TOO_EARLY,
                                    true
                                );
                            }

                            return (AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE, true);
                        }
                    } else {
                        if (
                            swapEndTimestamp - closableSwapInput.timeBeforeMaturityAllowedToCloseSwapByCommunity >
                            closableSwapInput.closeTimestamp
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

    /// @notice Calculates the swap unwind PnL value.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when user/account/client wants to close the swap, represented in seconds without 18 decimals
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
        uint256 endTimestamp = getSwapEndTimestamp(swap.openTimestamp, swap.tenor);

        require(closingTimestamp <= endTimestamp, AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE);

        uint256 time = endTimestamp - closingTimestamp;

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

    /// @notice Calculates the swap unwind opening fee amount for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swapOpenTimestamp moment when swap is opened, represented in seconds without 18 decimals
    /// @param swapNotional swap notional, represented in 18 decimals
    /// @param swapTenor swap tenor
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param openingFeeRateCfg opening fee rate taken from Protocol configuration, represented in 18 decimals
    /// @return swapOpeningFeeAmount swap opening fee amount, represented in 18 decimals
    function calculateSwapUnwindOpeningFeeAmount(
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        IporTypes.SwapTenor swapTenor,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) internal pure returns (uint256 swapOpeningFeeAmount) {
        require(closingTimestamp >= swapOpenTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        /// @dev 1e36 = 1e18 * 1e18, To achieve result in 18 decimals when there is multiplication of 3 numbers in 18 decimals, we need to divide by 1e36.
        swapOpeningFeeAmount = IporMath.division(
            swapNotional *
                openingFeeRateCfg *
                IporMath.division(
                    ((getSwapEndTimestamp(swapOpenTimestamp, swapTenor) - swapOpenTimestamp) -
                        (closingTimestamp - swapOpenTimestamp)) * 1e18,
                    365 days
                ),
            1e36
        );
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
                    ((getSwapEndTimestamp(swap.openTimestamp, swap.tenor) - swap.openTimestamp) -
                        (closingTimestamp - swap.openTimestamp)) * 1e18,
                    365 days
                ),
            1e36
        );
    }

    /// @notice Gets swap end timestamp based on swap tenor
    /// @return swap end timestamp in seconds without 18 decimals
    function getSwapEndTimestamp(uint256 openTimestamp, IporTypes.SwapTenor tenor) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return openTimestamp + 28 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return openTimestamp + 60 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return openTimestamp + 90 days;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }

    function validateAllowanceToCloseSwap(AmmTypes.SwapClosableStatus closableStatus) internal pure {
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_ALREADY_CLOSED) {
            revert(AmmErrors.INCORRECT_SWAP_STATUS);
        }
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE) {
            revert(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR);
        }
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY) {
            revert(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY);
        }
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_CANNOT_CLOSE_WITH_UNWIND_ACTION_IS_TOO_EARLY) {
            revert(AmmErrors.CANNOT_CLOSE_SWAP_WITH_UNWIND_ACTION_IS_TOO_EARLY);
        }
    }
}
