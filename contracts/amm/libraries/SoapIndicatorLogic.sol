// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/AmmErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/math/InterestRates.sol";
import "./types/StorageInternalTypes.sol";

library SoapIndicatorLogic {
    using SafeCast for uint256;
    using InterestRates for uint256;

    function calculateSoapPayFixed(
        StorageInternalTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalIbtQuantity * ibtPrice).toInt256() -
            (si.totalNotional + calculateHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256();
    }

    function calculateSoapReceiveFixed(
        StorageInternalTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalNotional + calculateHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256() -
            (si.totalIbtQuantity * ibtPrice).toInt256();
    }

    function rebalanceWhenOpenSwap(
        StorageInternalTypes.SoapIndicatorsMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure returns (StorageInternalTypes.SoapIndicatorsMemory memory) {
        uint256 averageInterestRate = calculateAverageInterestRateWhenOpenSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        uint256 hypotheticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;

        return si;
    }

    function rebalanceWhenCloseSwap(
        StorageInternalTypes.SoapIndicatorsMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure returns (StorageInternalTypes.SoapIndicatorsMemory memory) {
        uint256 newAverageInterestRate = calculateAverageInterestRateWhenCloseSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        if (si.totalNotional != derivativeNotional) {
            uint256 currentHypoteticalInterestTotal = calculateHyphoteticalInterestTotal(
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

    function calculateHyphoteticalInterestTotal(
        StorageInternalTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp
    ) internal pure returns (uint256) {
        return
            si.hypotheticalInterestCumulative +
            calculateHypotheticalInterestDelta(
                calculateTimestamp,
                si.rebalanceTimestamp,
                si.totalNotional + si.hypotheticalInterestCumulative,
                si.averageInterestRate
            );
    }

    function calculateHypotheticalInterestDelta(
        uint256 calculateTimestamp,
        uint256 lastRebalanceTimestamp,
        uint256 totalNotional,
        uint256 averageInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= lastRebalanceTimestamp,
            AmmErrors.CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP
        );
        return
            totalNotional.calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
                averageInterestRate * (calculateTimestamp - lastRebalanceTimestamp)
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
