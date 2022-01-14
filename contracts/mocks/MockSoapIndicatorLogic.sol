// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/SoapIndicatorLogic.sol";

contract MockSoapIndicatorLogic {
    function calculateSoapPayFixed(
        DataTypes.SoapIndicator memory si,
        uint256 ibtPrice,
        uint256 timestamp
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateSoapPayFixed(si, ibtPrice, timestamp);
    }

	function calculateSoapReceiveFixed(
        DataTypes.SoapIndicator memory si,
        uint256 ibtPrice,
        uint256 timestamp
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateSoapReceiveFixed(si, ibtPrice, timestamp);
    }

    //@notice For highest precision there is no division by D18 * D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiSoapPayFixed(
        DataTypes.SoapIndicator memory si,
        uint256 ibtPrice,
        uint256 timestamp
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateQuasiSoapPayFixed(si, ibtPrice, timestamp);
    }

	function calculateQuasiSoapReceiveFixed(
        DataTypes.SoapIndicator memory si,
        uint256 ibtPrice,
        uint256 timestamp
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateQuasiSoapReceiveFixed(si, ibtPrice, timestamp);
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) public pure returns(DataTypes.SoapIndicator memory){
        return
            SoapIndicatorLogic.rebalanceWhenOpenPosition(
                si,
                rebalanceTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );
    }

    function rebalanceWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) external pure returns(DataTypes.SoapIndicator memory){
        return
            SoapIndicatorLogic.rebalanceWhenClosePosition(
                si,
                rebalanceTimestamp,
                derivativeOpenTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );
    }

    function calculateQuasiInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateQuasiInterestPaidOut(
                calculateTimestamp,
                derivativeOpenTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate
            );
    }

    function calculateQuasiHyphoteticalInterestTotal(
        DataTypes.SoapIndicator memory si,
        uint256 timestamp
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateQuasiHyphoteticalInterestTotal(
                si,
                timestamp
            );
    }

    //division by Constants.YEAR_IN_SECONDS * 1e54 postponed at the end of calculation
    function calculateQuasiHypotheticalInterestDelta(
        DataTypes.SoapIndicator memory si,
        uint256 timestamp
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
                si,
                timestamp
            );
    }

    function calculateInterestRateWhenOpenPosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateInterestRateWhenOpenPosition(
                si,
                derivativeNotional,
                derivativeFixedInterestRate
            );
    }

    function calculateInterestRateWhenClosePosition(
        DataTypes.SoapIndicator memory si,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateInterestRateWhenClosePosition(
                si,
                derivativeNotional,
                derivativeFixedInterestRate
            );
    }
}
