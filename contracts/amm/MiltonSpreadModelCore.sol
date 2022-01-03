// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/AmmMath.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from "../libraries/AmmMath.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import {Errors} from "../Errors.sol";

contract MiltonSpreadModelCore {

	function _calculateSoapPlus(int256 soap, uint256 derivativesBalance)
        internal
        pure
        returns (uint256)
    {
        if (soap > 0) {
            return
                AmmMath.division(
                    uint256(soap) * Constants.D18,
                    derivativesBalance
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
            return
                Constants.D18 -
                (utilizationRateLegWithPosition -
                    AmmMath.division(
                        lambda *
                            (utilizationRateLegWithoutPosition -
                                utilizationRateLegWithPosition),
                        Constants.D18
                    ));
        }
    }
	
	//@notice Calculates utilization rate including position which is opened
    function _calculateUtilizationRateWithPosition(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                (derivativesBalance + derivativeDeposit) * Constants.D18,
                liquidityPoolBalance + derivativeOpeningFee
            );
    }

	//URleg(0)
    function _calculateUtilizationRateWithoutPosition(
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance
    ) internal pure returns (uint256) {
        return
            AmmMath.division(
                derivativesBalance * Constants.D18,
                liquidityPoolBalance + derivativeOpeningFee
            );
    }
}