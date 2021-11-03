// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';
import "./SoapIndicatorLogic.sol";

library TotalSoapIndicatorLogic {

    using SoapIndicatorLogic for DataTypes.SoapIndicator;

    function calculateSoap(
        DataTypes.TotalSoapIndicator storage tsi,
        uint256 calculationTimestamp,
        uint256 ibtPrice, uint256 multiplicator
    ) public view returns (int256 soapPf, int256 soapRf) {
        return (soapPf = tsi.pf.calculateSoap(ibtPrice, calculationTimestamp, multiplicator), soapRf = tsi.rf.calculateSoap(ibtPrice, calculationTimestamp, multiplicator));
    }

    function calculateQuasiSoap(
        DataTypes.TotalSoapIndicator storage tsi,
        uint256 calculationTimestamp,
        uint256 ibtPrice, uint256 multiplicator
    ) public view returns (int256 soapPf, int256 soapRf) {
        return (soapPf = tsi.pf.calculateQuasiSoap(ibtPrice, calculationTimestamp, multiplicator), soapRf = tsi.rf.calculateQuasiSoap(ibtPrice, calculationTimestamp, multiplicator));
    }

    function rebalanceSoapWhenOpenPosition(
        DataTypes.TotalSoapIndicator storage tsi,
        uint8 direction,
        uint256 rebalanceTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity,
        uint256 multiplicator
    ) public {
        if (direction == uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)) {
            tsi.pf.rebalanceWhenOpenPosition(
                rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity, multiplicator);
        }
        if (direction == uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed)) {
            tsi.rf.rebalanceWhenOpenPosition(
                rebalanceTimestamp, derivativeNotional, derivativeFixedInterestRate, derivativeIbtQuantity, multiplicator);
        }
    }

    function rebalanceSoapWhenClosePosition(
        DataTypes.TotalSoapIndicator storage tsi,
        uint8 direction,
        uint256 rebalanceTimestamp,
        uint256 derivativeOpenTimestamp,
        uint256 derivativeNotional,
        uint256 derivativeFixedInterestRate,
        uint256 derivativeIbtQuantity,
        uint256 multiplicator
    ) public {
        if (direction == uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)) {
            tsi.pf.rebalanceWhenClosePosition(
                rebalanceTimestamp, derivativeOpenTimestamp, derivativeNotional,
                derivativeFixedInterestRate, derivativeIbtQuantity, multiplicator);
        }
        if (direction == uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed)) {
            tsi.rf.rebalanceWhenClosePosition(
                rebalanceTimestamp, derivativeOpenTimestamp, derivativeNotional,
                derivativeFixedInterestRate, derivativeIbtQuantity, multiplicator);
        }
    }
}
