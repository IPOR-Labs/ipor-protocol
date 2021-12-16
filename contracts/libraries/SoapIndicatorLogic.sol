// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { AmmMath } from "../libraries/AmmMath.sol";
import { Errors } from "../Errors.sol";
import { Constants } from "../libraries/Constants.sol";

library SoapIndicatorLogic {
    function calculateSoap(
        DataTypes.SoapIndicator memory si,
        uint256 ibtPrice,
        uint256 timestamp
    ) internal pure returns (int256) {
        return
            AmmMath.divisionInt(
                calculateQuasiSoap(si, ibtPrice, timestamp),
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            );
    }

    //@notice For highest precision there is no division by D18 * D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiSoap(
        DataTypes.SoapIndicator memory si,
        uint256 ibtPrice,
        uint256 timestamp
    ) internal pure returns (int256) {
        if (
            si.direction == 0
        ) {
            return
                int256(
                    si.totalIbtQuantity *
                        ibtPrice *
                        Constants.WAD_YEAR_IN_SECONDS
                ) -
                int256(
                    si.totalNotional *
                        Constants.WAD_P2_YEAR_IN_SECONDS +
                        calculateQuasiHyphoteticalInterestTotal(si, timestamp)
                );
        } else {
            return
                int256(
                    si.totalNotional *
                        Constants.WAD_P2_YEAR_IN_SECONDS +
                        calculateQuasiHyphoteticalInterestTotal(si, timestamp)
                ) -
                int256(
                    si.totalIbtQuantity *
                        ibtPrice *
                        Constants.WAD_YEAR_IN_SECONDS
                );
        }
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) pure internal {
        //TODO: here potential re-entrancy
        uint256 averageInterestRate = calculateInterestRateWhenOpenPosition(
            si,
            derivativeNotional,
            derivativeFixedInterestRate
        );
        uint256 quasiHypotheticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
                si,
                rebalanceTimestamp
            );

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;
    }

    function rebalanceWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) pure internal {
        uint256 currentQuasiHypoteticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
                si,
                rebalanceTimestamp
            );

        uint256 quasiInterestPaidOut = calculateQuasiInterestPaidOut(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate
        );

        uint256 quasiHypotheticalInterestTotal = currentQuasiHypoteticalInterestTotal -
                quasiInterestPaidOut;

        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;

        uint256 averageInterestRate = calculateInterestRateWhenClosePosition(
            si,
            derivativeNotional,
            derivativeFixedInterestRate
        );
        //TODO: here potential re-entrancy
        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional - derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
    }

    function calculateQuasiInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= derivativeOpenTimestamp,
            Errors.MILTON_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP
        );
        return
            derivativeNotional *
            derivativeFixedInterestRate *
            (calculateTimestamp - derivativeOpenTimestamp) *
            Constants.D18;
    }

    function calculateQuasiHyphoteticalInterestTotal(
        DataTypes.SoapIndicator memory si,
        uint256 timestamp
    ) internal pure returns (uint256) {
        return
            si.quasiHypotheticalInterestCumulative +
            calculateQuasiHypotheticalInterestDelta(si, timestamp);
    }

    //division by Constants.YEAR_IN_SECONDS * 1e54 postponed at the end of calculation
    function calculateQuasiHypotheticalInterestDelta(
        DataTypes.SoapIndicator memory si,
        uint256 timestamp
    ) internal pure returns (uint256) {
        require(
            timestamp >= si.rebalanceTimestamp,
            Errors
                .MILTON_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP
        );
        return
            si.totalNotional *
            si.averageInterestRate *
            ((timestamp - si.rebalanceTimestamp) * Constants.D18);
    }

    function calculateInterestRateWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                (si.totalNotional *
                    si.averageInterestRate +
                    derivativeNotional *
                    derivativeFixedInterestRate),
                (si.totalNotional + derivativeNotional)
            );
    }

    function calculateInterestRateWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            derivativeNotional <= si.totalNotional,
            Errors.MILTON_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL
        );
        if (derivativeNotional == si.totalNotional) {
            return 0;
        } else {
            return
                AmmMath.division(
                    (si.totalNotional *
                        si.averageInterestRate -
                        derivativeNotional *
                        derivativeFixedInterestRate),
                    (si.totalNotional - derivativeNotional)
                );
        }
    }
}
