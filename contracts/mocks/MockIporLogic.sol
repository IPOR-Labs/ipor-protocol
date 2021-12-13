// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/IporLogic.sol";

contract MockIporLogic {
    function accrueQuasiIbtPrice(
        DataTypes.IPOR memory ipor,
        uint256 accrueTimestamp
    ) public pure returns (uint256) {
        return IporLogic.accrueQuasiIbtPrice(ipor, accrueTimestamp);
    }

    // function accrueQuasiIbtPrice(
    //     uint256 indexValue,
    //     uint256 quasiIbtPrice,
    //     uint256 indexTimestamp,
    //     uint256 accrueTimestamp
    // ) public pure returns (uint256) {
    //     return
    //         IporLogic.accrueQuasiIbtPrice(
    //             indexValue,
    //             quasiIbtPrice,
    //             indexTimestamp,
    //             accrueTimestamp
    //         );
    // }

    function calculateExponentialMovingAverage(
        uint256 lastExponentialMovingAverage,
        uint256 indexValue,
        uint256 decayFactor
    ) public pure returns (uint256) {
        return
            IporLogic.calculateExponentialMovingAverage(
                lastExponentialMovingAverage,
                indexValue,
                decayFactor
            );
    }
}
