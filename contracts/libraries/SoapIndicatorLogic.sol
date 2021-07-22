// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library SoapIndicatorLogic {

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 rebalanceTimestamp,
        uint256 ibtPrice,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 averageInterestRate = calculatInterestRateWhenOpenPosition(si, derivativeNotional, derivativeFixedInterestRate);
        uint256 hypotheticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = 333;//si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;

        //TODO: send event
    }

    function updateWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 averageInterestRate = calculatInterestRateWhenClosePosition(si, derivativeNotional, derivativeFixedInterestRate);

        uint256 hypotheticalInterestTotal = calculateHyphoteticalInterestTotal(si, rebalanceTimestamp);

        //TODO:O_paidOut,

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulative = hypotheticalInterestTotal;
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
        return (si.totalNotional * si.averageInterestRate - derivativeNotional * derivativeFixedInterestRate)
        / (si.totalNotional + derivativeNotional);
    }

    function calculateSoapPayFixed(DataTypes.SoapIndicator memory si, uint256 ibtPrice) public returns (uint256){
        return si.totalIbtQuantity * ibtPrice - (si.totalNotional + si.hypotheticalInterestCumulative);
    }

    function calculateSoapRecFixed(DataTypes.SoapIndicator memory si, uint256 ibtPrice, uint256 derivativeNotional) public returns(uint256){
        return (si.totalNotional + si.hypotheticalInterestCumulative) - si.totalIbtQuantity * ibtPrice;
    }
}