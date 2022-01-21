// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../amm/MiltonSpreadModel.sol";

contract MockMiltonSpreadModel is MiltonSpreadModel {
    constructor(address iporConfiguration)
        MiltonSpreadModel(iporConfiguration)
    {}

    function testCalculateSpreadPayFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soap
    ) public view returns (uint256 spreadValue) {
        return
            _calculateSpreadPayFixed(
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soap
            );
    }

    function testCalculateSpreadRecFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soap
    ) public view returns (uint256 spreadValue) {
        return
            _calculateSpreadRecFixed(
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soap
            );
    }

    function calculateDemandComponentPayFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapPayFixed
    ) public view returns (uint256) {
        return
            _calculateDemandComponentPayFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                soapPayFixed
            );
    }

    function calculateAtParComponentPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) public view returns (uint256) {
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
    ) public pure returns (uint256) {
        return
            _calculateHistoricalDeviationPayFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage,
                maxSpreadValue
            );
    }

    function calculateAdjustedUtilizationRatePayFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRatePayFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                lambda
            );
    }

    function calculateDemandComponentRecFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        int256 soapRecFixed
    ) public view returns (uint256) {
        return
            _calculateDemandComponentRecFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
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
    ) public pure returns (uint256) {
        return
            _calculateHistoricalDeviationRecFixed(
                kHist,
                iporIndexValue,
                exponentialMovingAverage,
                maxSpreadValue
            );
    }

    function calculateAdjustedUtilizationRateRecFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRateRecFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedDerivativesBalance,
                recFixedDerivativesBalance,
                lambda
            );
    }
}
