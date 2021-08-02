// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library SoapIndicatorLogic {

    function calculateSoap(
        DataTypes.SoapIndicator storage si,
        uint256 ibtPrice,
        uint256 timestamp) public view returns (int256){
        if (si.direction == DataTypes.DerivativeDirection.PayFixedReceiveFloating) {
            return int256(si.totalIbtQuantity * ibtPrice / Constants.MILTON_DECIMALS_FACTOR)
            - int256(si.totalNotional + si.hypotheticalInterestCumulative + calculateHypotheticalInterestDelta(si, timestamp));
        } else {
            return int256(si.totalNotional + si.hypotheticalInterestCumulative + calculateHypotheticalInterestDelta(si, timestamp))
            - int256(si.totalIbtQuantity * ibtPrice / Constants.MILTON_DECIMALS_FACTOR);
        }
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 averageInterestRate = calculatInterestRateWhenOpenPosition(si, derivativeNotional, derivativeFixedInterestRate);
        uint256 hypotheticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
    }

    function rebalanceWhenClosePosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 interestPaidOut = calculateInterestPaidOut(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate);

        uint256 averageInterestRate = calculatInterestRateWhenClosePosition(si, derivativeNotional, derivativeFixedInterestRate);
        uint256 hypotheticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp) - interestPaidOut;

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional - derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
    }

    function calculateInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        require(calculateTimestamp >= derivativeOpenTimestamp, Errors.AMM_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP);
        return derivativeNotional * derivativeFixedInterestRate * (calculateTimestamp - derivativeOpenTimestamp)
        / Constants.YEAR_IN_SECONDS / Constants.MILTON_DECIMALS_FACTOR;
    }

    function calculateHyphoteticalInterestTotal(DataTypes.SoapIndicator memory si, uint256 timestamp) public pure returns (uint256){
        return si.hypotheticalInterestCumulative + calculateHypotheticalInterestDelta(si, timestamp);
    }

    function calculateHypotheticalInterestDelta(DataTypes.SoapIndicator memory si, uint256 timestamp) public pure returns (uint256) {
        return (si.totalNotional * si.averageInterestRate * (timestamp - si.rebalanceTimestamp) / Constants.YEAR_IN_SECONDS) / Constants.MILTON_DECIMALS_FACTOR;
    }

    function calculatInterestRateWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        return (si.totalNotional * si.averageInterestRate + derivativeNotional * derivativeFixedInterestRate)
        / (si.totalNotional + derivativeNotional);

    }

    function calculatInterestRateWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        require(derivativeNotional <= si.totalNotional, Errors.AMM_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL);
        if (derivativeNotional == si.totalNotional) {
            return 0;
        } else {
            return (si.totalNotional * si.averageInterestRate - derivativeNotional * derivativeFixedInterestRate)
            / (si.totalNotional - derivativeNotional);
        }

    }

    function calculateSoapPayFixed(DataTypes.SoapIndicator memory si, uint256 ibtPrice) public pure returns (uint256){
        return si.totalIbtQuantity * ibtPrice - (si.totalNotional + si.hypotheticalInterestCumulative);
    }

    function calculateSoapRecFixed(DataTypes.SoapIndicator memory si, uint256 ibtPrice) public pure returns (uint256){
        return (si.totalNotional + si.hypotheticalInterestCumulative) - si.totalIbtQuantity * ibtPrice;
    }
}