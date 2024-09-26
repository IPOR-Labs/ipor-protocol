// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../../interfaces/types/IporTypes.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/math/InterestRates.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../libraries/RiskIndicatorsValidatorLib.sol";
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
            1e18 + IporMath.division(leverage * openingFeeRate * getTenorInDays(tenor), 365 * 1e18)
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
            pnlValue = calculatePnlPayFixed(
                swap.openTimestamp,
                swap.collateral,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                closingTimestamp,
                mdIbtPrice
            );
        } else if (swap.direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            pnlValue = calculatePnlReceiveFixed(
                swap.openTimestamp,
                swap.collateral,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                closingTimestamp,
                mdIbtPrice
            );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }
    }

    /// @notice Calculates Profit and Loss (PnL) for a pay fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swapOpenTimestamp moment when swap is opened, represented in seconds
    /// @param swapCollateral collateral value, represented in 18 decimals
    /// @param swapNotional swap notional, represented in 18 decimals
    /// @param swapFixedInterestRate fixed interest rate on a swap, represented in 18 decimals
    /// @param swapIbtQuantity IBT quantity, represented in 18 decimals
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return pnlValue swap PnL, represented in 18 decimals
    /// @dev Calculated PnL not taken into consideration potential unwinding of the swap.
    function calculatePnlPayFixed(
        uint256 swapOpenTimestamp,
        uint256 swapCollateral,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(
            swapOpenTimestamp,
            swapNotional,
            swapFixedInterestRate,
            swapIbtQuantity,
            closingTimestamp,
            mdIbtPrice
        );

        pnlValue = normalizePnlValue(swapCollateral, interestFloating.toInt256() - interestFixed.toInt256());
    }

    /// @notice Calculates Profit and Loss (PnL) for a receive fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swapOpenTimestamp moment when swap is opened, represented in seconds
    /// @param swapCollateral collateral value, represented in 18 decimals
    /// @param swapNotional swap notional, represented in 18 decimals
    /// @param swapFixedInterestRate fixed interest rate on a swap, represented in 18 decimals
    /// @param swapIbtQuantity IBT quantity, represented in 18 decimals
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return pnlValue swap PnL, represented in 18 decimals
    /// @dev Calculated PnL not taken into consideration potential unwinding of the swap.
    function calculatePnlReceiveFixed(
        uint256 swapOpenTimestamp,
        uint256 swapCollateral,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(
            swapOpenTimestamp,
            swapNotional,
            swapFixedInterestRate,
            swapIbtQuantity,
            closingTimestamp,
            mdIbtPrice
        );

        pnlValue = normalizePnlValue(swapCollateral, interestFixed.toInt256() - interestFloating.toInt256());
    }

    /// @notice Calculates interest including continuous capitalization for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swapOpenTimestamp moment when swap is opened, represented in seconds without 18 decimals
    /// @param swapNotional swap notional, represented in 18 decimals
    /// @param swapFixedInterestRate fixed interest rate on a swap, represented in 18 decimals
    /// @param swapIbtQuantity IBT quantity, represented in 18 decimals
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return interestFixed fixed interest chunk, represented in 18 decimals
    /// @return interestFloating floating interest chunk, represented in 18 decimals
    function calculateInterest(
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (uint256 interestFixed, uint256 interestFloating) {
        require(closingTimestamp >= swapOpenTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        interestFixed = calculateInterestFixed(
            swapNotional,
            swapFixedInterestRate,
            closingTimestamp - swapOpenTimestamp
        );

        interestFloating = calculateInterestFloating(swapIbtQuantity, mdIbtPrice);
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

    /// @notice Splits opening fee amount into liquidity pool and treasury portions
    /// @param openingFeeAmount opening fee amount, represented in 18 decimals
    /// @param openingFeeForTreasurePortionRate opening fee for treasury portion rate taken from Protocol configuration, represented in 18 decimals
    /// @return feeForLiquidityPoolAmount liquidity pool portion of opening fee, represented in 18 decimals
    /// @return feeForTreasuryAmount treasury portion of opening fee, represented in 18 decimals
    function splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePortionRate
    ) internal pure returns (uint256 feeForLiquidityPoolAmount, uint256 feeForTreasuryAmount) {
        feeForTreasuryAmount = IporMath.division(openingFeeAmount * openingFeeForTreasurePortionRate, 1e18);
        feeForLiquidityPoolAmount = openingFeeAmount - feeForTreasuryAmount;
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

    /// @notice Normalizes swap value to collateral value. Absolute value Swap PnL can't be higher than collateral.
    /// @param collateral collateral value, represented in 18 decimals
    /// @param pnlValue swap PnL, represented in 18 decimals
    function normalizePnlValue(uint256 collateral, int256 pnlValue) internal pure returns (int256) {
        int256 intCollateral = collateral.toInt256();

        if (pnlValue > 0) {
            if (pnlValue < intCollateral) {
                return pnlValue;
            } else {
                return intCollateral;
            }
        } else {
            if (pnlValue < -intCollateral) {
                return -intCollateral;
            } else {
                return pnlValue;
            }
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
}
