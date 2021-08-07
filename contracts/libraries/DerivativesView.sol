// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library DerivativesView {
    //@notice FOR FRONTEND
    function getPositions(DataTypes.MiltonDerivatives storage miltonDerivatives
    ) external view returns (DataTypes.IporDerivative[] memory) {
        DataTypes.IporDerivative[] memory _derivatives = new DataTypes.IporDerivative[](miltonDerivatives.ids.length);
        for (uint256 i = 0; i < miltonDerivatives.ids.length; i++) {
            _derivatives[i] = miltonDerivatives.items[miltonDerivatives.ids[i]].item;
        }
        return _derivatives;

    }

    function getUserPositions(
        DataTypes.MiltonDerivatives storage miltonDerivatives,
        address user
    ) external view returns (DataTypes.IporDerivative[] memory) {
        DataTypes.IporDerivative[] memory _derivatives = new DataTypes.IporDerivative[](miltonDerivatives.userDerivativeIds[user].length);
        for (uint256 i = 0; i < miltonDerivatives.userDerivativeIds[user].length; i++) {
            _derivatives[i] = miltonDerivatives.items[miltonDerivatives.userDerivativeIds[user][i]].item;
        }
        return _derivatives;
    }

}