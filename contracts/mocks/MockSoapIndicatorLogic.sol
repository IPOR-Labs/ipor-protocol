// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/SoapIndicatorLogic.sol";

contract MockSoapIndicatorLogic {
    function calculateSoapPayFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
        uint256 ibtPrice
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateSoapPayFixed(si, calculateTimestamp, ibtPrice);
    }

	function calculateSoapReceiveFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateSoapReceiveFixed(si, calculateTimestamp, ibtPrice);
    }

    //@notice For highest precision there is no division by D18 * D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiSoapPayFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice        
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateQuasiSoapPayFixed(si, calculateTimestamp, ibtPrice);
    }

	function calculateQuasiSoapReceiveFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice        
    ) public pure returns (int256) {
        return SoapIndicatorLogic.calculateQuasiSoapReceiveFixed(si, calculateTimestamp, ibtPrice);
    }

    function rebalanceWhenOpenPosition(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) public pure returns(DataTypes.SoapIndicatorMemory memory){
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
        DataTypes.SoapIndicatorMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) external pure returns(DataTypes.SoapIndicatorMemory memory){
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
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateQuasiHyphoteticalInterestTotal(
                si,
                calculateTimestamp
            );
    }

    //division by Constants.YEAR_IN_SECONDS * 1e54 postponed at the end of calculation
    function calculateQuasiHypotheticalInterestDelta(
        uint256 calculateTimestamp,
		uint256 lastRebalanceTimestamp,
		uint256 totalNotional,
		uint256 averageInterestRate        
    ) public pure returns (uint256) {
        return
            SoapIndicatorLogic.calculateQuasiHypotheticalInterestDelta(
                calculateTimestamp,
                lastRebalanceTimestamp,
				totalNotional,
				averageInterestRate
            );
    }

    function calculateInterestRateWhenOpenPosition(
        DataTypes.SoapIndicatorMemory memory si,
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
        DataTypes.SoapIndicatorMemory memory si,
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
