// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/types/AmmStorageTypes.sol";
import "../../libraries/errors/AmmErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/math/InterestRates.sol";
import "../../amm/libraries/SoapIndicatorLogic.sol";

/// @title Basic logic related with SOAP indicators when rebalance
library SoapIndicatorRebalanceLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    /// @notice Update SOAP indicators when open swap
    /// @param si SOAP indicators
    /// @param rebalanceTimestamp timestamp when the rebalance is executed
    /// @param derivativeNotional notional of the swap which is going to be opened and influence the SOAP
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @param swapIbtQuantity IBT quantity of the swap
    /// @return updated SOAP indicators
    function rebalanceWhenOpenSwap(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 rebalanceTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity
    ) external pure returns (AmmStorageTypes.SoapIndicators memory) {
        uint256 averageInterestRate = calculateAverageInterestRateWhenOpenSwap(
            si.totalNotional,
            si.averageInterestRate,
            swapNotional,
            swapFixedInterestRate
        );

        uint256 hypotheticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + swapNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + swapIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;

        return si;
    }

    /// @notice Update SOAP indicators when close swap
    /// @param si SOAP indicators
    /// @param rebalanceTimestamp timestamp when the rebalance is executed
    /// @param swapOpenTimestamp timestamp when the swap was opened
    /// @param swapNotional notional of the swap which is going to be closed and influence the SOAP
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @param swapIbtQuantity IBT quantity of the swap
    /// @return updated SOAP indicators
    function rebalanceWhenCloseSwap(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 rebalanceTimestamp,
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate,
        uint256 swapIbtQuantity
    ) external pure returns (AmmStorageTypes.SoapIndicators memory) {
        uint256 newAverageInterestRate = calculateAverageInterestRateWhenCloseSwap(
            si.totalNotional,
            si.averageInterestRate,
            swapNotional,
            swapFixedInterestRate
        );

        if (si.totalNotional != derivativeNotional) {
            uint256 currentHypoteticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
                si,
                rebalanceTimestamp
            );

            uint256 interestPaidOut = calculateInterestPaidOut(
                rebalanceTimestamp,
                swapOpenTimestamp,
                swapNotional,
                swapFixedInterestRate
            );

            uint256 hypotheticalInterestTotal = currentHypoteticalInterestTotal - interestPaidOut;

            si.rebalanceTimestamp = rebalanceTimestamp;
            si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
            si.totalNotional = si.totalNotional - swapNotional;
            si.totalIbtQuantity = si.totalIbtQuantity - swapIbtQuantity;
            si.averageInterestRate = newAverageInterestRate;
        } else {
            /// @dev when newAverageInterestRate = 0 it means in IPOR Protocol is closing the LAST derivative on this leg.
            si.rebalanceTimestamp = rebalanceTimestamp;
            si.hypotheticalInterestCumulative = 0;
            si.totalNotional = 0;
            si.totalIbtQuantity = 0;
            si.averageInterestRate = 0;
        }

        return si;
    }

    /// @notice Calculate the interest paid out of the swap when close it
    /// @param calculateTimestamp timestamp when the rebalance is executed
    /// @param swapOpenTimestamp timestamp when the swap was opened
    /// @param swapNotional notional of the swap
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @return interest paid out, represented in 18 decimals
    function calculateInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(calculateTimestamp >= swapOpenTimestamp, AmmErrors.CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);
        return
            swapNotional.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                swapFixedInterestRate * (calculateTimestamp - swapOpenTimestamp)
            );
    }

    /// @notice Calculate the average interest rate when open a swap
    /// @param totalNotional total notional balance
    /// @param averageInterestRate average interest rate
    /// @param swapNotional notional of the swap
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @return average interest rate, represented in 18 decimals
    function calculateAverageInterestRateWhenOpenSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 swapNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                (totalNotional * averageInterestRate + swapNotional * swapFixedInterestRate),
                (totalNotional + swapNotional)
            );
    }

    /// @notice Calculate the average interest rate when close a swap
    /// @param totalNotional total notional balance
    /// @param averageInterestRate average interest rate for all opened swaps in AMM
    /// @param swapNotional notional of the swap
    /// @param swapFixedInterestRate fixed interest rate of the swap
    /// @return average interest rate, represented in 18 decimals
    function calculateAverageInterestRateWhenCloseSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 swapNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(swapNotional <= totalNotional, AmmErrors.SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL);
        if (swapNotional == totalNotional) {
            return 0;
        } else {
            return
                IporMath.division(
                    (totalNotional * averageInterestRate - derivativeNotional * swapFixedInterestRate),
                    (totalNotional - derivativeNotional)
                );
        }
    }
}
