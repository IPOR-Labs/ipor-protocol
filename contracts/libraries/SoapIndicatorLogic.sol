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
        uint256 timestamp) public view returns (int256) {
        if (si.direction == DataTypes.DerivativeDirection.PayFixedReceiveFloating) {
            return int256(AmmMath.division(si.totalIbtQuantity * ibtPrice, Constants.MILTON_DECIMALS_FACTOR))
            - int256(si.totalNotional + si.hypotheticalInterestCumulative + calculateHypotheticalInterestDelta(si, timestamp));
        } else {
            return int256(si.totalNotional + si.hypotheticalInterestCumulative + calculateHypotheticalInterestDelta(si, timestamp))
            - int256(AmmMath.division(si.totalIbtQuantity * ibtPrice, Constants.MILTON_DECIMALS_FACTOR));
        }
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 averageInterestRate = calculateInterestRateWhenOpenPosition(si, derivativeNotional, derivativeFixedInterestRate);
        uint256 hypotheticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
    }

    event LogDebug(string name, uint256 value);

    function rebalanceWhenClosePosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 currentHypoteticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp);

        uint256 interestPaidOut = calculateInterestPaidOut(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate);
        uint256 hypotheticalInterestTotal = currentHypoteticalInterestTotal - interestPaidOut;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
        uint256 averageInterestRate = calculateInterestRateWhenClosePosition(si, derivativeNotional, derivativeFixedInterestRate);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional - derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;

    }

    function calculateInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        require(calculateTimestamp >= derivativeOpenTimestamp, Errors.AMM_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP);
        return AmmMath.division(
            derivativeNotional * derivativeFixedInterestRate * (calculateTimestamp - derivativeOpenTimestamp),
            Constants.YEAR_IN_SECONDS_WITH_FACTOR
        );
    }

    function calculateHyphoteticalInterestTotal(DataTypes.SoapIndicator memory si, uint256 timestamp) public pure returns (uint256){
        return si.hypotheticalInterestCumulative + calculateHypotheticalInterestDelta(si, timestamp);
    }

    function calculateHypotheticalInterestDelta(DataTypes.SoapIndicator memory si, uint256 timestamp) public pure returns (uint256) {
        require(timestamp >= si.rebalanceTimestamp, Errors.AMM_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP);
        return AmmMath.division(
            si.totalNotional * si.averageInterestRate * (timestamp - si.rebalanceTimestamp),
            Constants.YEAR_IN_SECONDS_WITH_FACTOR
        );
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
        require(derivativeNotional <= si.totalNotional, Errors.AMM_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL);
        if (derivativeNotional == si.totalNotional) {
            return 0;
        } else {
            return AmmMath.division(
                (si.totalNotional * si.averageInterestRate - derivativeNotional * derivativeFixedInterestRate),
                (si.totalNotional - derivativeNotional)
            );
        }
    }

    function calculateSoapPayFixed(DataTypes.SoapIndicator memory si, uint256 ibtPrice) public pure returns (uint256){
        return si.totalIbtQuantity * ibtPrice - (si.totalNotional + si.hypotheticalInterestCumulative);
    }

    function calculateSoapRecFixed(DataTypes.SoapIndicator memory si, uint256 ibtPrice) public pure returns (uint256){
        return (si.totalNotional + si.hypotheticalInterestCumulative) - si.totalIbtQuantity * ibtPrice;
    }
}