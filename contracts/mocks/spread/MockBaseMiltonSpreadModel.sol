// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../amm/MiltonSpreadModel.sol";

contract MockBaseMiltonSpreadModel is MiltonSpreadModel {
    function testCalculateSpreadPremiumsPayFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soap
    ) public pure returns (uint256 spreadValue) {
        DataTypes.MiltonTotalBalanceMemory memory balance = DataTypes
            .MiltonTotalBalanceMemory(
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                0,
                0,
                0,
                liquidityPoolBalance,
                0
            );
        return
            _calculateSpreadPremiumsPayFixed(
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                balance,
                soap
            );
    }

    function testCalculateSpreadPremiumsRecFixed(
        DataTypes.AccruedIpor memory accruedIpor,
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soap
    ) public pure returns (uint256 spreadValue) {
        DataTypes.MiltonTotalBalanceMemory memory balance = DataTypes
            .MiltonTotalBalanceMemory(
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                0,
                0,
                0,
                liquidityPoolBalance,
                0
            );
        return
            _calculateSpreadPremiumsRecFixed(
                accruedIpor,
                swapCollateral,
                swapOpeningFee,
                balance,
                soap
            );
    }

    function calculateDemandComponentPayFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soapPayFixed
    ) public pure returns (uint256) {
        return
            _calculateDemandComponentPayFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                soapPayFixed
            );
    }

    function calculateAtParComponentPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) public pure returns (uint256) {
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
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRatePayFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                lambda
            );
    }

    function calculateDemandComponentRecFixed(
        uint256 swapCollateral,
        uint256 swapOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        int256 soapRecFixed
    ) public pure returns (uint256) {
        return
            _calculateDemandComponentRecFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                soapRecFixed
            );
    }

    function calculateAtParComponentRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) public pure returns (uint256) {
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
        uint256 payFixedSwapsBalance,
        uint256 receiveFixedSwapsBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRateRecFixed(
                swapCollateral,
                swapOpeningFee,
                liquidityPoolBalance,
                payFixedSwapsBalance,
                receiveFixedSwapsBalance,
                lambda
            );
    }
}
