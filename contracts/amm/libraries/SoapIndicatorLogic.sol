// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../types/MiltonStorageTypes.sol";
import {IporMath} from "../../utils/math/IporMath.sol";
import {IporErrors} from "../../IporErrors.sol";
import {Constants} from "../../utils/Constants.sol";

library SoapIndicatorLogic {
    using SafeCast for uint256;

    function calculateQuasiSoapPayFixed(
        MiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalIbtQuantity * ibtPrice * Constants.WAD_YEAR_IN_SECONDS).toInt256() -
            (si.totalNotional *
                Constants.WAD_P2_YEAR_IN_SECONDS +
                calculateQuasiHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256();
    }

    //@notice For highest precision there is no division by D18 * D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiSoapReceiveFixed(
        MiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256) {
        return
            (si.totalNotional *
                Constants.WAD_P2_YEAR_IN_SECONDS +
                calculateQuasiHyphoteticalInterestTotal(si, calculateTimestamp)).toInt256() -
            (si.totalIbtQuantity * ibtPrice * Constants.WAD_YEAR_IN_SECONDS).toInt256();
    }

    function rebalanceWhenOpenSwap(
        MiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure returns (MiltonStorageTypes.SoapIndicatorsMemory memory) {
        uint256 averageInterestRate = calculateInterestRateWhenOpenSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );
        uint256 quasiHypotheticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );

        si.rebalanceTimestamp = rebalanceTimestamp.toUint32();
        si.totalNotional = si.totalNotional + derivativeNotional.toUint128();
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;
        return si;
    }

    function rebalanceWhenCloseSwap(
        MiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure returns (MiltonStorageTypes.SoapIndicatorsMemory memory) {
        uint256 currentQuasiHypoteticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
            si,
            rebalanceTimestamp
        );

        uint256 quasiInterestPaidOut = calculateQuasiInterestPaidOut(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            swapFixedInterestRate
        );

        uint256 quasiHypotheticalInterestTotal = currentQuasiHypoteticalInterestTotal -
            quasiInterestPaidOut;

        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;

        uint256 averageInterestRate = calculateInterestRateWhenCloseSwap(
            si.totalNotional,
            si.averageInterestRate,
            derivativeNotional,
            swapFixedInterestRate
        );

        si.rebalanceTimestamp = rebalanceTimestamp.toUint32();
        si.totalNotional = si.totalNotional - derivativeNotional.toUint128();
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        return si;
    }

    function calculateQuasiInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= derivativeOpenTimestamp,
            IporErrors.MILTON_CALC_TIMESTAMP_HIGHER_THAN_SWAP_OPEN_TIMESTAMP
        );
        return
            derivativeNotional *
            swapFixedInterestRate *
            (calculateTimestamp - derivativeOpenTimestamp) *
            Constants.D18;
    }

    function calculateQuasiHyphoteticalInterestTotal(
        MiltonStorageTypes.SoapIndicatorsMemory memory si,
        uint256 calculateTimestamp
    ) internal pure returns (uint256) {
        return
            si.quasiHypotheticalInterestCumulative +
            calculateQuasiHypotheticalInterestDelta(
                calculateTimestamp,
                si.rebalanceTimestamp,
                si.totalNotional,
                si.averageInterestRate
            );
    }

    //division by Constants.YEAR_IN_SECONDS * 1e54 postponed at the end of calculation
    function calculateQuasiHypotheticalInterestDelta(
        uint256 calculateTimestamp,
        uint256 lastRebalanceTimestamp,
        uint256 totalNotional,
        uint256 averageInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= lastRebalanceTimestamp,
            IporErrors.MILTON_CALC_TIMESTAMP_LTHAN_SI_REBALANCE_TIMESTAMP
        );
        return
            totalNotional *
            averageInterestRate *
            ((calculateTimestamp - lastRebalanceTimestamp) * Constants.D18);
    }

    function calculateInterestRateWhenOpenSwap(
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

    function calculateInterestRateWhenCloseSwap(
        uint256 totalNotional,
        uint256 averageInterestRate,
        uint256 derivativeNotional,
        uint256 swapFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            derivativeNotional <= totalNotional,
            IporErrors.MILTON_SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL
        );
        if (derivativeNotional == totalNotional) {
            return 0;
        } else {
            return
                IporMath.division(
                    (totalNotional *
                        averageInterestRate -
                        derivativeNotional *
                        swapFixedInterestRate),
                    (totalNotional - derivativeNotional)
                );
        }
    }
}
