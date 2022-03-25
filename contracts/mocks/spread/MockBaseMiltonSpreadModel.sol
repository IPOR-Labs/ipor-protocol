// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../amm/spread/MiltonSpreadModel.sol";

contract MockBaseMiltonSpreadModel is MiltonSpreadModel {
    function testCalculateSpreadPremiumsPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        uint256 liquidityPoolBalance,
        uint256 payFixedTotalCollateralBalance,
        uint256 receiveFixedTotalCollateralBalance
    ) public pure returns (uint256 spreadValue) {
        IporTypes.MiltonBalancesMemory memory balance = IporTypes.MiltonBalancesMemory(
            payFixedTotalCollateralBalance,
            receiveFixedTotalCollateralBalance,
            liquidityPoolBalance,
            0
        );
        return _calculateSpreadPremiumsPayFixed(soap, accruedIpor, balance);
    }

    function testCalculateSpreadPremiumsRecFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        uint256 liquidityPoolBalance,
        uint256 payFixedTotalCollateralBalance,
        uint256 receiveFixedTotalCollateralBalance
    ) public pure returns (uint256 spreadValue) {
        IporTypes.MiltonBalancesMemory memory balance = IporTypes.MiltonBalancesMemory(
            payFixedTotalCollateralBalance,
            receiveFixedTotalCollateralBalance,
            liquidityPoolBalance,
            0
        );
        return _calculateSpreadPremiumsRecFixed(soap, accruedIpor, balance);
    }

    function testCalculateAdjustedUtilizationRate(
        uint256 utilizationRateLegWithSwap,
        uint256 utilizationRateLegWithoutSwap,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRate(
                utilizationRateLegWithSwap,
                utilizationRateLegWithoutSwap,
                lambda
            );
    }

    function calculateDemandComponentPayFixed(
        uint256 liquidityPoolBalance,
        uint256 payFixedTotalCollateralBalance,
        uint256 receiveFixedTotalCollateralBalance,
        int256 soapPayFixed
    ) public pure returns (uint256) {
        return
            _calculateDemandComponentPayFixed(
                liquidityPoolBalance,
                payFixedTotalCollateralBalance,
                receiveFixedTotalCollateralBalance,
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
        uint256 liquidityPoolBalance,
        uint256 payFixedTotalCollateralBalance,
        uint256 receiveFixedTotalCollateralBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRatePayFixed(
                liquidityPoolBalance,
                payFixedTotalCollateralBalance,
                receiveFixedTotalCollateralBalance,
                lambda
            );
    }

    function calculateDemandComponentRecFixed(
        uint256 liquidityPoolBalance,
        uint256 payFixedTotalCollateralBalance,
        uint256 receiveFixedTotalCollateralBalance,
        int256 soapRecFixed
    ) public pure returns (uint256) {
        return
            _calculateDemandComponentRecFixed(
                liquidityPoolBalance,
                payFixedTotalCollateralBalance,
                receiveFixedTotalCollateralBalance,
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
        uint256 liquidityPoolBalance,
        uint256 payFixedTotalCollateralBalance,
        uint256 receiveFixedTotalCollateralBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRateRecFixed(
                liquidityPoolBalance,
                payFixedTotalCollateralBalance,
                receiveFixedTotalCollateralBalance,
                lambda
            );
    }
}
