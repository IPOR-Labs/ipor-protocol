// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { IporErrors } from "../IporErrors.sol";
import { Constants } from "../libraries/Constants.sol";

library DerivativesView {
    //@notice FOR FRONTEND
    //TODO: fix it, looks bad, DoS, possible out of gas
    function getPositions(DataTypes.MiltonDerivatives storage miltonDerivatives)
        external
        view
        returns (DataTypes.IporDerivative[] memory)
    {
        DataTypes.IporDerivative[]
            memory derivatives = new DataTypes.IporDerivative[](
                miltonDerivatives.ids.length
            );
        for (uint256 i = 0; i < miltonDerivatives.ids.length; i++) {
            derivatives[i] = miltonDerivatives
                .items[miltonDerivatives.ids[i]]
                .item;
        }
        return derivatives;
    }

    function getUserPositions(
        DataTypes.MiltonDerivatives storage miltonDerivatives,
        address user
    ) external view returns (DataTypes.IporDerivative[] memory) {
        DataTypes.IporDerivative[]
            memory derivatives = new DataTypes.IporDerivative[](
                miltonDerivatives.userDerivativeIds[user].length
            );
        for (
            uint256 i = 0;
            i < miltonDerivatives.userDerivativeIds[user].length;
            i++
        ) {
            derivatives[i] = miltonDerivatives
                .items[miltonDerivatives.userDerivativeIds[user][i]]
                .item;
        }
        return derivatives;
    }
}
