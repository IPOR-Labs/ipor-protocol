// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { IporMath } from "../libraries/IporMath.sol";
import { IporErrors } from "../IporErrors.sol";
import { Constants } from "../libraries/Constants.sol";

library SoapIndicatorLogic {
    function calculateSoapPayFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice        
    ) internal pure returns (int256) {
        return
            IporMath.divisionInt(
                calculateQuasiSoapPayFixed(si, calculateTimestamp, ibtPrice),
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            );
    }

	function calculateSoapReceiveFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice        
    ) internal pure returns (int256) {
        return
            IporMath.divisionInt(
                calculateQuasiSoapReceiveFixed(si, calculateTimestamp, ibtPrice),
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            );
    }

	function calculateQuasiSoapPayFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice        
    ) internal pure returns (int256) {

            return
                int256(
                    si.totalIbtQuantity *
                        ibtPrice *
                        Constants.WAD_YEAR_IN_SECONDS
                ) -
                int256(
                    si.totalNotional *
                        Constants.WAD_P2_YEAR_IN_SECONDS +
                        calculateQuasiHyphoteticalInterestTotal(si, calculateTimestamp)
                );
        
    }
    //@notice For highest precision there is no division by D18 * D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiSoapReceiveFixed(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 calculateTimestamp,
		uint256 ibtPrice        
    ) internal pure returns (int256) {
        
            return
                int256(
                    si.totalNotional *
                        Constants.WAD_P2_YEAR_IN_SECONDS +
                        calculateQuasiHyphoteticalInterestTotal(si, calculateTimestamp)
                ) -
                int256(
                    si.totalIbtQuantity *
                        ibtPrice *
                        Constants.WAD_YEAR_IN_SECONDS
                );
        
    }

    function rebalanceWhenOpenSwap(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure returns(DataTypes.SoapIndicatorMemory memory) {
        //TODO: here potential re-entrancy
        uint256 averageInterestRate = calculateInterestRateWhenOpenSwap(
            si.totalNotional,
			si.averageInterestRate,
            derivativeNotional,
            derivativeFixedInterestRate
        );
        uint256 quasiHypotheticalInterestTotal = calculateQuasiHyphoteticalInterestTotal(
                si,
                rebalanceTimestamp
            );

        si.rebalanceTimestamp = uint32(rebalanceTimestamp);
        si.totalNotional = si.totalNotional + uint128(derivativeNotional);
        si.totalIbtQuantity = si.totalIbtQuantity + derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
        si.quasiHypotheticalInterestCumulative = quasiHypotheticalInterestTotal;
		return si;
    }

    function rebalanceWhenCloseSwap(
        DataTypes.SoapIndicatorMemory memory si,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure returns(DataTypes.SoapIndicatorMemory memory){
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

        uint256 averageInterestRate = calculateInterestRateWhenCloseSwap(
			si.totalNotional,
			si.averageInterestRate,
            derivativeNotional,
            derivativeFixedInterestRate
        );
        //TODO: here potential re-entrancy
        si.rebalanceTimestamp = uint32(rebalanceTimestamp);
        si.totalNotional = si.totalNotional - uint128(derivativeNotional);
        si.totalIbtQuantity = si.totalIbtQuantity - derivativeIbtQuantity;
        si.averageInterestRate = averageInterestRate;
		return si;
    }

    function calculateQuasiInterestPaidOut(
        uint256 calculateTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            calculateTimestamp >= derivativeOpenTimestamp,
            IporErrors.MILTON_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP
        );
        return
            derivativeNotional *
            derivativeFixedInterestRate *
            (calculateTimestamp - derivativeOpenTimestamp) *
            Constants.D18;
    }

    function calculateQuasiHyphoteticalInterestTotal(
        DataTypes.SoapIndicatorMemory memory si,
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
            IporErrors
                .MILTON_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP
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
        uint256 derivativeFixedInterestRate
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                (totalNotional *
                    averageInterestRate +
                    derivativeNotional *
                    derivativeFixedInterestRate),
                (totalNotional + derivativeNotional)
            );
    }

    function calculateInterestRateWhenCloseSwap(
		uint256 totalNotional,
		uint256 averageInterestRate,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate
    ) internal pure returns (uint256) {
        require(
            derivativeNotional <= totalNotional,
            IporErrors.MILTON_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL
        );
        if (derivativeNotional == totalNotional) {
            return 0;
        } else {
            return
                IporMath.division(
                    (totalNotional *
                        averageInterestRate -
                        derivativeNotional *
                        derivativeFixedInterestRate),
                    (totalNotional - derivativeNotional)
                );
        }
    }
}
