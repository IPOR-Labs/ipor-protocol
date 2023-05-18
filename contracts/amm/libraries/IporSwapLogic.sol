// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../interfaces/types/AmmTypes.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";

library IporSwapLogic {
    using SafeCast for uint256;

    /// @param timeToMaturityInDays time to maturity in days, not represented in 18 decimals
    /// @param totalAmount total amount represented in 18 decimals
    /// @param leverage swap leverage, represented in 18 decimals
    /// @param liquidationDepositAmount liquidation deposit amount, represented in 18 decimals
    /// @param iporPublicationFeeAmount IPOR publication fee amount, represented in 18 decimals
    /// @param openingFeeRate opening fee rate, represented in 18 decimals
    function calculateSwapAmount(
        uint256 timeToMaturityInDays,
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
            Constants.D18 + IporMath.division(leverage * openingFeeRate * timeToMaturityInDays, 365 * Constants.D18)
        );
        notional = IporMath.division(leverage * collateral, Constants.D18);
        openingFee = availableAmount - collateral;
    }

    function calculatePayoffPayFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 quasiIFixed, uint256 quasiIFloating) = calculateQuasiInterest(swap, closingTimestamp, mdIbtPrice);

        swapValue = _normalizeSwapValue(
            swap.collateral,
            IporMath.divisionInt(quasiIFloating.toInt256() - quasiIFixed.toInt256(), Constants.WAD_YEAR_IN_SECONDS_INT)
        );
    }

    function calculatePayoffReceiveFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 swapValue) {
        (uint256 quasiIFixed, uint256 quasiIFloating) = calculateQuasiInterest(swap, closingTimestamp, mdIbtPrice);

        swapValue = _normalizeSwapValue(
            swap.collateral,
            IporMath.divisionInt(quasiIFixed.toInt256() - quasiIFloating.toInt256(), Constants.WAD_YEAR_IN_SECONDS_INT)
        );
    }

    function calculateSwapUnwindValue(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        int256 swapPayoffToDate,
        uint256 oppositeLegFixedRate,
        uint256 openingFeeRateForSwapUnwind
    ) internal pure returns (int256 swapUnwindValue) {
        require(closingTimestamp <= swap.endTimestamp, MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE);

        swapUnwindValue =
            swapPayoffToDate +
            IporMath.divisionInt(
                swap.notional.toInt256() *
                    (oppositeLegFixedRate.toInt256() - swap.fixedInterestRate.toInt256()) *
                    ((swap.endTimestamp - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp)).toInt256(),
                Constants.WAD_YEAR_IN_SECONDS_INT
            ) -
            openingFeeRateForSwapUnwind.toInt256();
    }

    /// @notice Calculates interests fixed and floating without division by Constants.D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterest(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (uint256 quasiIFixed, uint256 quasiIFloating) {
        require(closingTimestamp >= swap.openTimestamp, MiltonErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        quasiIFixed = calculateQuasiInterestFixed(
            swap.notional,
            swap.fixedInterestRate,
            closingTimestamp - swap.openTimestamp
        );

        quasiIFloating = calculateQuasiInterestFloating(swap.ibtQuantity, mdIbtPrice);
    }

    /// @notice Calculates interest fixed without division by Constants.D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) internal pure returns (uint256) {
        return notional * Constants.WAD_YEAR_IN_SECONDS + notional * swapFixedInterestRate * swapPeriodInSeconds;
    }

    /// @notice Calculates interest floating without division by Constants.D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice)
        internal
        pure
        returns (uint256)
    {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when swap is closed)
        return ibtQuantity * ibtCurrentPrice * Constants.YEAR_IN_SECONDS;
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

    /// @notice Check closable status for Swap given as a parameter.
    /// @param iporSwap The swap to be checked
    /// @param inputParameters The input parameters for closing swap
    /// @param configuration The configuration for closing swap
    /// @return closableStatus Closable status for Swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Account is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function getClosableStatus(
        IporTypes.IporSwapMemory memory iporSwap,
        CloseSwapInputParameters memory inputParameters,
        CloseSwapConfiguration memory configuration
    ) internal view returns (uint256) {
        if (iporSwap.state != uint256(AmmTypes.SwapState.ACTIVE)) {
            return 1;
        }

        if (inputParameters.account != configuration.owner) {
            uint256 absPayoff = IporMath.absoluteValue(inputParameters.payoff);

            uint256 minPayoffToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                iporSwap.collateral,
                configuration.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            if (inputParameters.closeTimestamp >= iporSwap.endTimestamp) {
                if (absPayoff < minPayoffToCloseBeforeMaturityByCommunity || absPayoff == iporSwap.collateral) {
                    if (
                        !_isLiquidator(inputParameters.account, configuration.liquidators) &&
                        inputParameters.account != iporSwap.buyer
                    ) {
                        return 2;
                    }
                }
            } else {
                uint256 minPayoffToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    iporSwap.collateral,
                    configuration.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPayoff >= minPayoffToCloseBeforeMaturityByBuyer &&
                        absPayoff < minPayoffToCloseBeforeMaturityByCommunity) || absPayoff == iporSwap.collateral
                ) {
                    if (
                        !_isLiquidator(inputParameters.account, configuration.liquidators) &&
                        inputParameters.account != iporSwap.buyer
                    ) {
                        return 2;
                    }
                }

                if (absPayoff < minPayoffToCloseBeforeMaturityByBuyer) {
                    if (inputParameters.account == iporSwap.buyer) {
                        if (
                            iporSwap.endTimestamp - configuration.timeBeforeMaturityAllowedToCloseSwapByBuyer >
                            inputParameters.closeTimestamp
                        ) {
                            return 3;
                        }
                    } else {
                        if (
                            iporSwap.endTimestamp - configuration.timeBeforeMaturityAllowedToCloseSwapByCommunity >
                            inputParameters.closeTimestamp
                        ) {
                            return 4;
                        }
                    }
                }
            }
        }

        return 0;
    }

    function _isLiquidator(address account, address[] memory liquidators) internal view returns (bool) {
        bool isLiquidator = false;
        for (uint256 i = 0; i < liquidators.length; i++) {
            if (liquidators[i] == account) {
                isLiquidator = true;
                break;
            }
        }
        return isLiquidator;
    }

    struct CloseSwapInputParameters {
        address account;
        int256 payoff;
        uint256 closeTimestamp;
    }

    struct CloseSwapConfiguration {
        address owner;
        address[] liquidators;
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyer;
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
    }
}
