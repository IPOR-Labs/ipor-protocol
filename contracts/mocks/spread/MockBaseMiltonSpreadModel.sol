// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../amm/spread/MiltonSpreadModel.sol";

contract MockBaseMiltonSpreadModel is MiltonSpreadModel {
    function testCalculateSpreadPremiumsPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance
    ) public pure returns (int256 spreadPremiums) {
        IporTypes.MiltonBalancesMemory memory balance = IporTypes.MiltonBalancesMemory(
            totalCollateralPayFixedBalance,
            totalCollateralReceiveFixedBalance,
            liquidityPoolBalance,
            0
        );
        return _calculateSpreadPremiumsPayFixed(soap, accruedIpor, balance);
    }

    function testCalculateSpreadPremiumsRecFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance
    ) public pure returns (int256 spreadPremiums) {
        IporTypes.MiltonBalancesMemory memory balance = IporTypes.MiltonBalancesMemory(
            totalCollateralPayFixedBalance,
            totalCollateralReceiveFixedBalance,
            liquidityPoolBalance,
            0
        );
        return _calculateSpreadPremiumsReceiveFixed(soap, accruedIpor, balance);
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
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        int256 soapPayFixed
    ) public pure returns (uint256) {
        return
            _calculateDemandComponentPayFixed(
                liquidityPoolBalance,
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance,
                soapPayFixed
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
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRatePayFixed(
                liquidityPoolBalance,
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance,
                lambda
            );
    }

    function calculateDemandComponentRecFixed(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        int256 soapRecFixed
    ) public pure returns (uint256) {
        return
            _calculateDemandComponentReceiveFixed(
                liquidityPoolBalance,
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance,
                soapRecFixed
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
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance,
        uint256 lambda
    ) public pure returns (uint256) {
        return
            _calculateAdjustedUtilizationRateRecFixed(
                liquidityPoolBalance,
                totalCollateralPayFixedBalance,
                totalCollateralReceiveFixedBalance,
                lambda
            );
    }
}
