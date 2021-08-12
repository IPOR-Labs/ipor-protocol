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
        uint256 timestamp) public returns (int256) {
        if (si.direction == DataTypes.DerivativeDirection.PayFixedReceiveFloating) {

//            emit LogDebug("soap", si.totalNotional + AmmMath.division(calculateHyphoteticalInterestTotalNumerator(si, timestamp), Constants.YEAR_IN_SECONDS_WITH_FACTOR));
            //TODO: totalNotional pomnozyc 1e18
            return int256(AmmMath.division(si.totalIbtQuantity * ibtPrice, 1e18))
            - int256(si.totalNotional + AmmMath.division(calculateHyphoteticalInterestTotalNumerator(si, timestamp), Constants.YEAR_IN_SECONDS * 1e36));
        } else {
            return int256(si.totalNotional + AmmMath.division(calculateHyphoteticalInterestTotalNumerator(si, timestamp), Constants.YEAR_IN_SECONDS * 1e36))
            - int256(AmmMath.division(si.totalIbtQuantity * ibtPrice, 1e18));
        }
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        //TODO: here potential re-entrancy
        uint256 averageInterestRate = calculateInterestRateWhenOpenPosition(si, derivativeNotional, derivativeFixedInterestRate);
        uint256 hypotheticalInterestTotalNumerator = calculateHyphoteticalInterestTotalNumerator(si, rebalanceTimestamp);

        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional + derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.hypotheticalInterestCumulativeNumerator = hypotheticalInterestTotalNumerator;

        emit LogDebug("hypotheticalInterestCumulativeRaw", AmmMath.division(si.hypotheticalInterestCumulativeNumerator, Constants.YEAR_IN_SECONDS_WITH_FACTOR));

    }

    event LogDebug(string name, uint256 value);

    function rebalanceWhenClosePosition(
        DataTypes.SoapIndicator storage si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity) public {

        uint256 currentHypoteticalInterestTotalNumerator = calculateHyphoteticalInterestTotalNumerator(si, rebalanceTimestamp);

        uint256 interestPaidOutNumerator = calculateInterestPaidOutNumerator(
            rebalanceTimestamp,
            derivativeOpenTimestamp,
            derivativeNotional,
            derivativeFixedInterestRate);

        uint256 hypotheticalInterestTotalNumerator = currentHypoteticalInterestTotalNumerator - interestPaidOutNumerator;

        si.hypotheticalInterestCumulativeNumerator = hypotheticalInterestTotalNumerator;

        uint256 averageInterestRate = calculateInterestRateWhenClosePosition(si, derivativeNotional, derivativeFixedInterestRate);
        //TODO: here potential re-entrancy
        si.rebalanceTimestamp = rebalanceTimestamp;
        si.totalNotional = si.totalNotional - derivativeNotional;
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;

        emit LogDebug("hypotheticalInterestCumulativeRaw", AmmMath.division(si.hypotheticalInterestCumulativeNumerator, Constants.YEAR_IN_SECONDS_WITH_FACTOR));


    }

    function calculateInterestPaidOutNumerator(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate) public pure returns (uint256) {
        require(calculateTimestamp >= derivativeOpenTimestamp, Errors.AMM_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP);
        return derivativeNotional * derivativeFixedInterestRate * (calculateTimestamp - derivativeOpenTimestamp) * Constants.MILTON_DECIMALS_FACTOR;
    }

    function calculateHyphoteticalInterestTotalNumerator(DataTypes.SoapIndicator memory si, uint256 timestamp) public returns (uint256){
        return si.hypotheticalInterestCumulativeNumerator + calculateHypotheticalInterestDeltaNumerator(si, timestamp);
    }

    //division by Constants.YEAR_IN_SECONDS * 1e54 postponed at the end of calculation
    function calculateHypotheticalInterestDeltaNumerator(DataTypes.SoapIndicator memory si, uint256 timestamp) public pure returns (uint256) {
        require(timestamp >= si.rebalanceTimestamp, Errors.AMM_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP);
        return si.totalNotional * si.averageInterestRate * ((timestamp - si.rebalanceTimestamp) * Constants.MILTON_DECIMALS_FACTOR);
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
}