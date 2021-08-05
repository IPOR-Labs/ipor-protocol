// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library DerivativesView {
    //@notice FOR FRONTEND
    function getPositions(
        DataTypes.IporDerivative[] storage derivatives
    ) external view returns (DataTypes.IporDerivative[] memory) {
        DataTypes.IporDerivative[] memory _derivatives = new DataTypes.IporDerivative[](derivatives.length);

        for (uint256 i = 0; i < derivatives.length; i++) {
            DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
                derivatives[i].indicator.iporIndexValue,
                derivatives[i].indicator.ibtPrice,
                derivatives[i].indicator.ibtQuantity,
                derivatives[i].indicator.fixedInterestRate
            );

            DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
                derivatives[i].fee.liquidationDepositAmount,
                derivatives[i].fee.openingAmount,
                derivatives[i].fee.iporPublicationAmount,
                derivatives[i].fee.spreadPercentage
            );
            _derivatives[i] = DataTypes.IporDerivative(
                derivatives[i].id,
                derivatives[i].state,
                derivatives[i].buyer,
                derivatives[i].asset,
                derivatives[i].direction,
                derivatives[i].depositAmount,
                fee,
                derivatives[i].leverage,
                derivatives[i].notionalAmount,
                derivatives[i].startingTimestamp,
                derivatives[i].endingTimestamp,
                indicator
            );

        }

        return _derivatives;

    }
}