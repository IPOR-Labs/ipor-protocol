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

    //@param indexValue indexValue represent in WAD
    //@param quasiIbtPrice quasiIbtPrice represent in WAD, quasi inform that IBT Price doesn't have final value, is required to divide by number of seconds in year
    //@dev return value represented in WAD
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
    //@dev return value represented in WAD
    function calculateExponentialMovingAverage(
        uint256 lastExponentialMovingAverage,
        uint256 indexValue,
        uint256 decayFactor
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                lastExponentialMovingAverage *
                    (Constants.D18 - decayFactor) +
                    indexValue *
                    decayFactor,
                Constants.D18
            );
    }

    function calculateExponentialWeightedMovingVariance(
        uint256 lastExponentialWeightedMovingVariance,
        uint256 exponentialMovingAverage,
        uint256 indexValue,
        uint256 alfa
    ) internal pure returns (uint256 result) {		

		require(alfa <= Constants.D18, Errors.MILTON_SPREAD_ALFA_CANNOT_BE_HIGHER_THAN_ONE);

		if (indexValue > exponentialMovingAverage) {
			result = AmmMath.division(
				alfa *(lastExponentialWeightedMovingVariance * Constants.D18 * Constants.D18
						+ (Constants.D18 - alfa) * (indexValue - exponentialMovingAverage) * (indexValue - exponentialMovingAverage)),
					 Constants.D18 * Constants.D18 * Constants.D18 
				 );
		} else {
			result = AmmMath.division(
				alfa *(lastExponentialWeightedMovingVariance * Constants.D18 * Constants.D18
						+ (Constants.D18 - alfa) * (exponentialMovingAverage - indexValue) * (exponentialMovingAverage-indexValue)),
					 Constants.D18 * Constants.D18 * Constants.D18 
				 );
		}

		require(result <= Constants.D18, Errors.MILTON_SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE);
        
    }
}
