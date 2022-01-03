// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../amm/MiltonSpreadModel.sol";

contract MockMiltonSpreadModel is MiltonSpreadModel {
	
	constructor(address iporConfiguration) MiltonSpreadModel(iporConfiguration){		
	}

    function calculateDemandComponentPayFixed(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapPayFixed
    ) public returns (uint256) {
        return
            _calculateDemandComponentPayFixed(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soapPayFixed
            );
    }

    function calculateAtParComponentPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) public returns (uint256) {
        return
            _calculateAtParComponentPayFixed(
                iporIndexValue,
                exponentialMovingAverage,
                exponentialWeightedMovingVariance
            );
    }

    function calculateHistoricalDeviationPayFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) public returns (uint256) {
        return
            _calculateHistoricalDeviationPayFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage,
                maxSpreadValue
            );
    }

    function calculateAdjustedUtilizationRatePayFixed(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) public returns (uint256) {
        return
            _calculateAdjustedUtilizationRatePayFixed(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                lambda
            );
    }

    function calculateDemandComponentRecFixed(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapRecFixed
    ) public returns (uint256) {
        return
            _calculateDemandComponentRecFixed(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soapRecFixed
            );
    }

    function calculateAtParComponentRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) public view returns (uint256) {
        return
            _calculateAtParComponentRecFixed(
                iporIndexValue,
                exponentialMovingAverage,
                exponentialWeightedMovingVariance
            );
    }

    function calculateHistoricalDeviationRecFixed(
        uint256 kHist,
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 maxSpreadValue
    ) public returns (uint256) {
        return
            _calculateHistoricalDeviationRecFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage,
                maxSpreadValue
            );
    }

    function calculateAdjustedUtilizationRateRecFixed(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) public returns (uint256) {
        return
            _calculateAdjustedUtilizationRateRecFixed(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                lambda
            );
    }
}
