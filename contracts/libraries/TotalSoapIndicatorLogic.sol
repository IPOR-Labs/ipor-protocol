// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { Errors } from "../Errors.sol";
import { Constants } from "../libraries/Constants.sol";
import "./SoapIndicatorLogic.sol";

library TotalSoapIndicatorLogic {
    using SoapIndicatorLogic for DataTypes.SoapIndicator;

    function calculateSoap(
        DataTypes.TotalSoapIndicator memory tsi,
        uint256 calculationTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256 soapPf, int256 soapRf) {
		
        return (
            soapPf = SoapIndicatorLogic.calculateSoap(tsi.pf, ibtPrice, calculationTimestamp),
            soapRf = SoapIndicatorLogic.calculateSoap(tsi.rf, ibtPrice, calculationTimestamp)
        );
    }

    function calculateQuasiSoap(
        DataTypes.TotalSoapIndicator memory tsi,
        uint256 calculationTimestamp,
        uint256 ibtPrice
    ) internal pure returns (int256 soapPf, int256 soapRf) {
        return (
            soapPf = tsi.pf.calculateQuasiSoap(ibtPrice, calculationTimestamp),
            soapRf = tsi.rf.calculateQuasiSoap(ibtPrice, calculationTimestamp)
        );
    }

    function rebalanceSoapWhenOpenPosition(
        DataTypes.TotalSoapIndicator memory tsi,
        uint8 direction,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure {
        if (
            direction ==
            uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
        ) {
            tsi.pf.rebalanceWhenOpenPosition(
                rebalanceTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );
        }
        if (
            direction ==
            uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed)
        ) {
            tsi.rf.rebalanceWhenOpenPosition(
                rebalanceTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );
        }
    }

    function rebalanceSoapWhenClosePosition(
        DataTypes.TotalSoapIndicator memory tsi,
        uint8 direction,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity
    ) internal pure {
        if (
            direction ==
            uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
        ) {
            tsi.pf.rebalanceWhenClosePosition(
                rebalanceTimestamp,
                derivativeOpenTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );
        }
        if (
            direction ==
            uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed)
        ) {
            tsi.rf.rebalanceWhenClosePosition(
                rebalanceTimestamp,
                derivativeOpenTimestamp,
                derivativeNotional,
                derivativeFixedInterestRate,
                derivativeIbtQuantity
            );
        }
    }
}
