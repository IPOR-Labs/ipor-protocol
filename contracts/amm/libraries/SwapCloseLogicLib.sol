// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "../../interfaces/types/AmmTypes.sol";
import "../../libraries/math/InterestRates.sol";
import "../../libraries/RiskManagementLogic.sol";
import "../../libraries/RiskIndicatorsValidatorLib.sol";
import "../../base/amm/libraries/SwapLogicBaseV1.sol";
import "../../base/amm/libraries/SwapCloseLogicLibBaseV1.sol";

library SwapCloseLogicLib {
    using SafeCast for uint256;
    using SafeCast for int256;
    using InterestRates for uint256;
    using InterestRates for int256;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    /// @notice Calculate swap unwind when unwind is required.
    /// @param unwindParams unwind parameters required to calculate swap unwind pnl value.
    /// @return swapUnwindPnlValue swap unwind PnL value
    /// @return swapUnwindFeeAmount swap unwind opening fee amount, sum of swapUnwindFeeLPAmount and swapUnwindFeeTreasuryAmount
    /// @return swapUnwindFeeLPAmount swap unwind opening fee LP amount
    /// @return swapUnwindFeeTreasuryAmount swap unwind opening fee treasury amount
    /// @return swapPnlValue swap PnL value includes swap PnL to date, swap unwind PnL value, this value NOT INCLUDE swap unwind fee amount.
    function calculateSwapUnwindWhenUnwindRequired(
        AmmTypes.UnwindParams memory unwindParams
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

        if (unwindParams.direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            oppositeRiskIndicators = unwindParams.riskIndicatorsInputs.receiveFixed.verify(
                unwindParams.poolCfg.asset,
                uint256(unwindParams.swap.tenor),
                uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                unwindParams.messageSigner
            );
            /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
            swapUnwindPnlValue = calculateSwapUnwindPnlValueNormalized(unwindParams, 1, oppositeRiskIndicators);
        } else if (unwindParams.direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            oppositeRiskIndicators = unwindParams.riskIndicatorsInputs.payFixed.verify(
                unwindParams.poolCfg.asset,
                uint256(unwindParams.swap.tenor),
                uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                unwindParams.messageSigner
            );
            /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
            swapUnwindPnlValue = calculateSwapUnwindPnlValueNormalized(unwindParams, 0, oppositeRiskIndicators);
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        swapPnlValue = SwapLogicBaseV1.normalizePnlValue(
            unwindParams.swap.collateral,
            unwindParams.swapPnlValueToDate + swapUnwindPnlValue
        );

        /// @dev swap unwind fee amount is independent of the swap unwind pnl value, takes into consideration notional.
        swapUnwindFeeAmount = SwapCloseLogicLibBaseV1.calculateSwapUnwindOpeningFeeAmount(
            unwindParams.swap.openTimestamp,
            unwindParams.swap.notional,
            unwindParams.swap.tenor,
            unwindParams.closeTimestamp,
            unwindParams.poolCfg.unwindingFeeRate
        );

        require(
            unwindParams.swap.collateral.toInt256() + swapPnlValue > swapUnwindFeeAmount.toInt256(),
            AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP
        );

        (swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount) = SwapLogicBaseV1.splitOpeningFeeAmount(
            swapUnwindFeeAmount,
            unwindParams.poolCfg.unwindingFeeTreasuryPortionRate
        );
    }

    function calculateSwapUnwindPnlValueNormalized(
        AmmTypes.UnwindParams memory unwindParams,
        uint256 direction,
        AmmTypes.OpenSwapRiskIndicators memory oppositeRiskIndicators
    ) internal view returns (int256) {
        return
            SwapLogicBaseV1.normalizePnlValue(
                unwindParams.swap.collateral,
                calculateSwapUnwindPnlValue(
                    unwindParams.swap,
                    unwindParams.direction,
                    unwindParams.closeTimestamp,
                    RiskManagementLogic.calculateOfferedRate(
                        direction,
                        unwindParams.swap.tenor,
                        unwindParams.swap.notional,
                        RiskManagementLogic.SpreadOfferedRateContext({
                            asset: unwindParams.poolCfg.asset,
                            ammStorage: unwindParams.poolCfg.ammStorage,
                            spreadRouter: unwindParams.spreadRouter,
                            minLeverage: unwindParams.poolCfg.minLeverage,
                            indexValue: unwindParams.indexValue
                        }),
                        oppositeRiskIndicators
                    )
                )
            );
    }

    /// @notice Calculates the swap unwind PnL value.
    /// @param swap Swap structure
    /// @param direction swap direction
    /// @param closingTimestamp moment when user wants to close the swap, represented in seconds without 18 decimals
    /// for particular swap at time when swap will be closed by the trader.
    /// @dev Equation for this calculation is:
    /// time - number of seconds left to swap until maturity divided by number of seconds in year
    /// Opposite Leg Fixed Rate - calculated fixed rate of opposite leg used for the virtual swap
    /// @dev If Swap is Pay Fixed Receive Floating then UnwindValue  = Current Swap PnL + Notional * (e^(Opposite Leg Fixed Rate * time) - e^(Swap Fixed Rate * time))
    /// @dev If Swap is Receive Fixed Pay Floating then UnwindValue  = Current Swap PnL + Notional * (e^(Swap Fixed Rate * time) - e^(Opposite Leg Fixed Rate * time))
    function calculateSwapUnwindPnlValue(
        AmmTypes.Swap memory swap,
        AmmTypes.SwapDirection direction,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) internal pure returns (int256 swapUnwindPnlValue) {
        AmmTypesBaseV1.Swap memory swapBaseV1;

        swapBaseV1.openTimestamp = swap.openTimestamp;
        swapBaseV1.tenor = swap.tenor;
        swapBaseV1.direction = direction;
        swapBaseV1.collateral = swap.collateral;
        swapBaseV1.notional = swap.notional;
        swapBaseV1.fixedInterestRate = swap.fixedInterestRate;

        return SwapCloseLogicLibBaseV1.calculateSwapUnwindPnlValue(swapBaseV1, closingTimestamp, oppositeLegFixedRate);
    }
}
