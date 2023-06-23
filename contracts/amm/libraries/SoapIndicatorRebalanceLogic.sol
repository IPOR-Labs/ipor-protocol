// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "contracts/interfaces/types/AmmStorageTypes.sol";
import "contracts/libraries/Constants.sol";
import "contracts/libraries/errors/AmmErrors.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/libraries/math/InterestRates.sol";
import "contracts/amm/libraries/SoapIndicatorLogic.sol";

library SoapIndicatorRebalanceLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    function rebalanceWhenOpenSwap(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) external pure returns (AmmStorageTypes.SoapIndicators memory) {
        uint256 averageInterestRate = calculateAverageInterestRateWhenOpenSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        uint256 hypotheticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;

        return si;
    }

    function rebalanceWhenCloseSwap(
        AmmStorageTypes.SoapIndicators memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) external pure returns (AmmStorageTypes.SoapIndicators memory) {
        uint256 newAverageInterestRate = calculateAverageInterestRateWhenCloseSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        if (si.totalNotional != derivativeNotional) {
            uint256 currentHypoteticalInterestTotal = SoapIndicatorLogic.calculateHyphoteticalInterestTotal(
                si,
                rebalanceTimestamp
            );

            uint256 interestPaidOut = calculateInterestPaidOut(
                rebalanceTimestamp,
                derivativeOpenTimestamp,
                derivativeNotional,
                swapFixedInterestRate
            );

            uint256 hypotheticalInterestTotal = currentHypoteticalInterestTotal - interestPaidOut;

            si.rebalanceTimestamp = rebalanceTimestamp;
            si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
            si.totalNotional = si.totalNotional - derivativeNotional;
            si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
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

    function calculateInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(calculateTimestamp >= derivativeOpenTimestamp, AmmErrors.CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);
        return
            derivativeNotional.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                swapFixedInterestRate * (calculateTimestamp - derivativeOpenTimestamp)
            );
    }

    function calculateAverageInterestRateWhenOpenSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                (totalNotional * averageInterestRate + derivativeNotional * swapFixedInterestRate),
                (totalNotional + derivativeNotional)
            );
    }

    function calculateAverageInterestRateWhenCloseSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(derivativeNotional <= totalNotional, AmmErrors.SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL);
        if (derivativeNotional == totalNotional) {
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
