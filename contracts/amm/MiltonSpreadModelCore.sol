// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/IporMath.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import {IporErrors} from "../IporErrors.sol";

contract MiltonSpreadModelCore {

	function _calculateSoapPlus(int256 soap, uint256 swapsBalance)
        internal
        pure
        returns (uint256)
    {
        if (soap > 0) {
            return
                IporMath.division(
                    uint256(soap) * Constants.D18,
                    swapsBalance
                );
        } else {
            return 0;
        }
    }

	function _calculateImbalanceFactorWithLambda(
        uint256 utilizationRateLegWithPosition,
        uint256 utilizationRateLegWithoutPosition,
        uint256 lambda
    ) internal pure returns (uint256) {
        if (
            utilizationRateLegWithPosition >= utilizationRateLegWithoutPosition
        ) {
            return Constants.D18 - utilizationRateLegWithPosition;
        } else {
			//TODO: clarify with quants if this value can be higher than 1 if yes then use int256 instead uint256 and prepare test for it
             return
                 Constants.D18 -
                 (utilizationRateLegWithPosition 
					 -
                    IporMath.division(
                        lambda *
                            (utilizationRateLegWithoutPosition -
                                utilizationRateLegWithPosition),
                        Constants.D18
                    )
				);
        }
    }
	
	//@notice Calculates utilization rate including position which is opened
    function _calculateUtilizationRateWithPosition(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 swapsBalance
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                (swapsBalance + swapCollateral) * Constants.D18,
                liquidityPoolBalance + swapOpeningFee
            );
    }

	//URleg(0)
    function _calculateUtilizationRateWithoutPosition(
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 swapsBalance
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                swapsBalance * Constants.D18,
                liquidityPoolBalance + swapOpeningFee
            );
    }
}