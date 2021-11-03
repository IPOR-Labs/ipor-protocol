// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {AmmMath} from '../libraries/AmmMath.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library SoapIndicatorLogic {

    function calculateSoap(
        DataTypes.SoapIndicator storage si,
        uint256 ibtPrice,
        uint256 timestamp,
        uint256 multiplicator) public view returns (int256) {
        return AmmMath.divisionInt(calculateQuasiSoap(si, ibtPrice, timestamp, multiplicator), Constants.MD_P2_YEAR_IN_SECONDS_INT);
    }

    //@notice For highest precision there is no division by Constants.MD_P2_YEAR_IN_SECONDS
    function calculateQuasiSoap(
        DataTypes.SoapIndicator storage si,
        uint256 ibtPrice,
        uint256 timestamp,
        uint256 multiplicator) public view returns (int256) {
        if (si.direction == DataTypes.DerivativeDirection.PayFixedReceiveFloating) {
            return int256(si.totalIbtQuantity * ibtPrice * multiplicator * Constants.YEAR_IN_SECONDS)
            - int256(si.totalNotional * multiplicator * multiplicator * Constants.YEAR_IN_SECONDS + calculateQuasiHyphoteticalInterestTotal(si, timestamp, multiplicator));
        } else {
            return int256(si.totalNotional * multiplicator * multiplicator * Constants.YEAR_IN_SECONDS + calculateQuasiHyphoteticalInterestTotal(si, timestamp, multiplicator))
            - int256(si.totalIbtQuantity * ibtPrice * multiplicator * Constants.YEAR_IN_SECONDS);
        }
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 mdDerivativeNotional,
        uint256 mdDerivativeFixedInterestRate,
        uint256 mdDerivativeIbtQuantity,
        uint256 multiplicator) public {

        //TODO: here potential re-entrancy
        uint256 averageInterestRate = calculateInterestRateWhenOpenPosition(si, mdDerivativeNotional, mdDerivativeFixedInterestRate);
        uint256 quasiHypotheticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(si, rebalanceTimestamp, multiplicator);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + mdDerivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + mdDerivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;
    }

    function rebalanceWhenClosePosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity,
        uint256 multiplicator) public {

        uint256 currentQuasiHypoteticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(si, rebalanceTimestamp, multiplicator);

        uint256 quasiInterestPaidOut = calculateQuasiInterestPaidOut(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate, multiplicator);

        uint256 quasiHypotheticalInterestTotal = currentQuasiHypoteticalInterestTotal - quasiInterestPaidOut;

        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;

        uint256 averageInterestRate = calculateInterestRateWhenClosePosition(si, derivativeNotional, derivativeFixedInterestRate);
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
        uint256 derivativeFixedInterestRate,
        uint256 multiplicator) public pure returns (uint256) {
        require(calculateTimestamp >= derivativeOpenTimestamp, Errors.MILTON_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP);
        return derivativeNotional * derivativeFixedInterestRate * (calculateTimestamp - derivativeOpenTimestamp) * multiplicator;
    }

    function calculateQuasiHyphoteticalInterestTotal(DataTypes.SoapIndicator memory si, uint256 timestamp, uint256 multiplicator) public pure returns (uint256){
        return si.quasiHypotheticalInterestCumulative + calculateQuasiHypotheticalInterestDelta(si, timestamp, multiplicator);
    }

    //division by Constants.YEAR_IN_SECONDS * 1e54 postponed at the end of calculation
    function calculateQuasiHypotheticalInterestDelta(DataTypes.SoapIndicator memory si, uint256 timestamp, uint256 multiplicator) public pure returns (uint256) {
        require(timestamp >= si.rebalanceTimestamp, Errors.MILTON_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP);
        return si.totalNotional * si.averageInterestRate * ((timestamp - si.rebalanceTimestamp) * multiplicator);
    }

    function calculateInterestRateWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        return AmmMath.division(
            (si.totalNotional * si.averageInterestRate + derivativeNotional * derivativeFixedInterestRate),
            (si.totalNotional + derivativeNotional)
        );
    }

    function calculateInterestRateWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        require(derivativeNotional <= si.totalNotional, Errors.MILTON_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL);
        if (derivativeNotional == si.totalNotional) {
            return 0;
        } else {
            return AmmMath.division(
                (si.totalNotional * si.averageInterestRate - derivativeNotional * derivativeFixedInterestRate),
                (si.totalNotional - derivativeNotional)
            );
        }
    }
}
