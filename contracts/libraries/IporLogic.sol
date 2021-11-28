// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { Errors } from "../Errors.sol";
import { Constants } from "../libraries/Constants.sol";
import { AmmMath } from "../libraries/AmmMath.sol";

library IporLogic {
    function accrueQuasiIbtPrice(
        DataTypes.IPOR memory ipor,
        uint256 accrueTimestamp
    ) internal pure returns (uint256) {
        return
            accrueQuasiIbtPrice(
                ipor.indexValue,
                ipor.quasiIbtPrice,
                ipor.blockTimestamp,
                accrueTimestamp
            );
    }

    function accrueQuasiIbtPrice(
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 indexTimestamp,
        uint256 accrueTimestamp
    ) internal pure returns (uint256) {
        require(
            accrueTimestamp >= indexTimestamp,
            Errors.WARREN_INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );
        return
            quasiIbtPrice + (indexValue * (accrueTimestamp - indexTimestamp));
    }

    //@notice ExpMovAv(n) = ExpMovAv(n-1) * (1 - d) + IPOR * d
    function calculateExponentialMovingAverage(
        uint256 lastExponentialMovingAverage,
        uint256 indexValue,
        uint256 decayFactor,
        uint256 multiplicator
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                lastExponentialMovingAverage *
                    (multiplicator - decayFactor) +
                    indexValue *
                    decayFactor,
                multiplicator
            );
    }
}
