// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import { DataTypes } from "../libraries/types/DataTypes.sol";
import { IporErrors } from "../IporErrors.sol";
import { Constants } from "../libraries/Constants.sol";
import { IporMath } from "../libraries/IporMath.sol";

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
            IporErrors.WARREN_INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );
        return
            quasiIbtPrice + (indexValue * (accrueTimestamp - indexTimestamp));
    }

    //@notice ExpMovAv(n) = ExpMovAv(n-1) * (1 - d) + IPOR * d
    //@dev return value represented in WAD
    function calculateExponentialMovingAverage(
        uint256 lastExponentialMovingAverage,
        uint256 indexValue,
        uint256 alpha
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                lastExponentialMovingAverage *
                    (Constants.D18 - alpha) +
                    indexValue *
                    alpha,
                Constants.D18
            );
    }

    function calculateExponentialWeightedMovingVariance(
        uint256 lastExponentialWeightedMovingVariance,
        uint256 exponentialMovingAverage,
        uint256 indexValue,
        uint256 alpha
    ) internal pure returns (uint256 result) {		

		require(alpha <= Constants.D18, IporErrors.MILTON_SPREAD_ALPHA_CANNOT_BE_HIGHER_THAN_ONE);

		if (indexValue > exponentialMovingAverage) {
			result = IporMath.division(
				alpha *(lastExponentialWeightedMovingVariance * Constants.D18 * Constants.D18
						+ (Constants.D18 - alpha) * (indexValue - exponentialMovingAverage) * (indexValue - exponentialMovingAverage)),
					 Constants.D18 * Constants.D18 * Constants.D18 
				 );
		} else {
			result = IporMath.division(
				alpha *(lastExponentialWeightedMovingVariance * Constants.D18 * Constants.D18
						+ (Constants.D18 - alpha) * (exponentialMovingAverage - indexValue) * (exponentialMovingAverage-indexValue)),
					 Constants.D18 * Constants.D18 * Constants.D18 
				 );
		}

		require(result <= Constants.D18, IporErrors.MILTON_SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE);
        
    }
}
