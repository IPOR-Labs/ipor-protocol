// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/Constants.sol";
import "../libraries/IporMath.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import {IporErrors} from "../IporErrors.sol";

contract MiltonSpreadModelCore {
    using SafeCast for int256;
	using SafeCast for uint256;

    function _calculateSoapPlus(int256 soap, uint256 swapsBalance)
        internal
        pure
        returns (uint256)
    {
        if (soap > 0) {
            return
                IporMath.division(
                    soap.toUint256() * Constants.D18,
                    swapsBalance
                );
        } else {
            return 0;
        }
    }

    function _calculateImbalanceFactorWithLambda(
        uint256 utilizationRateLegWithPosition,
        uint256 utilizationRateLegWithoutSwap,
        uint256 lambda
    ) internal pure returns (uint256) {
        if (utilizationRateLegWithPosition >= utilizationRateLegWithoutSwap) {
            return Constants.D18 - utilizationRateLegWithPosition;
        } else {
            //TODO: clarify with quants if this value can be higher than 1 if yes then use int256 instead uint256 and prepare test for it
            return
                Constants.D18 -
                (utilizationRateLegWithPosition -
                    IporMath.division(
                        lambda *
                            (utilizationRateLegWithoutSwap -
                                utilizationRateLegWithPosition),
                        Constants.D18
                    ));
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
    function _calculateUtilizationRateWithoutSwap(
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

    function _calculateHistoricalDeviationPayFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage < iporIndexValue) {
            return 0;
        } else {
            uint256 mu = IporMath.absoluteValue(
                exponentialMovingAverage.toInt256() - iporIndexValue.toInt256()
            );
            if (mu == Constants.D18) {
                return maxSpreadValue;
            } else {
                return
                    IporMath.division(
                        kHist * Constants.D18,
                        Constants.D18 - mu
                    );
            }
        }
    }

    function _calculateHistoricalDeviationRecFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) internal pure returns (uint256) {
        if (exponentialMovingAverage > iporIndexValue) {
            return 0;
        } else {
            uint256 mu = IporMath.absoluteValue(
                exponentialMovingAverage.toInt256() - iporIndexValue.toInt256()
            );
            if (mu == Constants.D18) {
                return maxSpreadValue;
            } else {
                return
                    IporMath.division(
                        kHist * Constants.D18,
                        Constants.D18 - mu
                    );
            }
        }
    }
}
