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

    function _calculateAdjustedUtilizationRate(
        uint256 utilizationRateLegWithSwap,
        uint256 utilizationRateLegWithoutSwap,
        uint256 lambda
    ) internal pure returns (uint256) {
        if (utilizationRateLegWithSwap >= utilizationRateLegWithoutSwap) {
            return utilizationRateLegWithSwap;
        } else {
			
            uint256 imbalanceFactor = IporMath.division(
                lambda *
                    (utilizationRateLegWithoutSwap -
                        utilizationRateLegWithSwap),
                Constants.D18
            );

            if (imbalanceFactor > utilizationRateLegWithSwap) {
                return 0;
            } else {
                return utilizationRateLegWithSwap - imbalanceFactor;
            }
        }
    }

    //@notice Calculates utilization rate including position which is opened
    function _calculateUtilizationRateWithPosition(
        uint256 liquidityPoolBalance,
        uint256 swapsBalance
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                swapsBalance * Constants.D18,
                liquidityPoolBalance
            );
    }

    //URleg(0)
    function _calculateUtilizationRateWithoutSwap(
        uint256 liquidityPoolBalance,
        uint256 swapsBalance
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                swapsBalance * Constants.D18,
                liquidityPoolBalance
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
            if (mu >= Constants.D18) {
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
