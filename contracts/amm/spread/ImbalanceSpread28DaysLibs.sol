// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./CalculateWeightedNotionalLibs.sol";


library ImbalanceSpread28DaysLibs {
    /// @notice Dto for the Weighted Notional
    struct SpreadInputData {
        IporTypes.AccruedIpor accruedIpor;
        IporTypes.SwapsBalanceMemory accruedBalance;
        uint256 swapNotional;
        uint256 maxLeverage;
        uint256 maxLpUtilizationPerLegRate;
        SpreadStorageLibs.StorageId storageId28Days;
        SpreadStorageLibs.StorageId storageId90Days;
    }



    function calculatePayFixedSpread(SpreadInputData memory inputData)
        internal
        returns (uint256 spreadValue)
    {
        uint256 lpDepth = CalculateWeightedNotionalLibs.calculateLpDepth(
            inputData.accruedBalance.liquidityPool,
            inputData.accruedBalance.totalCollateralPayFixed,
            inputData.accruedBalance.totalCollateralReceiveFixed
        );

        uint256 notionalDepth = IporMath.division(
            lpDepth * inputData.maxLeverage * inputData.maxLpUtilizationPerLegRate,
            1e36
        );

        (
            uint256 oldWeightedNotionalPayFixed,
            uint256 weightedNotionalReceiveFixed
        ) = CalculateWeightedNotionalLibs.getWeightedNotional(
                inputData.storageId28Days,
                inputData.storageId90Days
            );
        uint256 newWeightedNotionalPayFixed = oldWeightedNotionalPayFixed + inputData.swapNotional;
        if (newWeightedNotionalPayFixed > weightedNotionalReceiveFixed) {
            uint256 oldSpread;
            if (oldWeightedNotionalPayFixed > weightedNotionalReceiveFixed) {
                oldSpread = calculateSpreadFunction(
                    notionalDepth,
                    oldWeightedNotionalPayFixed - weightedNotionalReceiveFixed
                );
            }
            uint256 newSpread = calculateSpreadFunction(
                notionalDepth,
                newWeightedNotionalPayFixed - weightedNotionalReceiveFixed
            );
            spreadValue = IporMath.division(oldSpread + newSpread, 2);
        } else {
            spreadValue = 0;
        }
    }

    function calculateReceiveFixedSpread(SpreadInputData memory inputData)
        internal
        returns (uint256 spreadValue)
    {
        uint256 lpDepth = CalculateWeightedNotionalLibs.calculateLpDepth(
            inputData.accruedBalance.liquidityPool,
            inputData.accruedBalance.totalCollateralPayFixed,
            inputData.accruedBalance.totalCollateralReceiveFixed
        );

        uint256 notionalDepth = IporMath.division(
            lpDepth * inputData.maxLeverage * inputData.maxLpUtilizationPerLegRate,
            1e36
        );

        (
            uint256 weightedNotionalPayFixed,
            uint256 oldWeightedNotionalReceiveFixed
        ) = CalculateWeightedNotionalLibs.getWeightedNotional(
                inputData.storageId28Days,
                inputData.storageId90Days
            );
        uint256 newWeightedNotionalReceiveFixed = oldWeightedNotionalReceiveFixed +
            inputData.swapNotional;
        if (newWeightedNotionalReceiveFixed > weightedNotionalPayFixed) {
            uint256 oldSpread;
            if (oldWeightedNotionalReceiveFixed > weightedNotionalPayFixed) {
                oldSpread = calculateSpreadFunction(
                    notionalDepth,
                    oldWeightedNotionalReceiveFixed - weightedNotionalPayFixed
                );
            }

            uint256 newSpread = calculateSpreadFunction(
                notionalDepth,
                newWeightedNotionalReceiveFixed - weightedNotionalPayFixed
            );
            spreadValue = IporMath.division(oldSpread + newSpread, 2);
        } else {
            spreadValue = 0;
        }
    }

    function calculateSpreadFunction(
        uint256 maxNotional, // lpDepth * leverage * maxUtilisation
        uint256 weightedNotional
    ) public view returns (uint256 spreadValue) {
        uint256 ratio = IporMath.division(weightedNotional * 1e18, maxNotional);
        if (ratio < 1e17) {
            spreadValue = IporMath.division(5e16 * ratio, 1e18);
            // 0% -> 0.5%
        } else if (ratio < 2e17) {
            spreadValue = IporMath.division(1e17 * ratio, 1e18) - 5e15;
            // 0.5% -> 1.5%
        } else if (ratio < 3e17) {
            spreadValue = IporMath.division(15e16 * ratio, 1e18) - 15e15;
            // 1.5% -> 3%
        } else if (ratio < 4e17) {
            spreadValue = IporMath.division(2e17 * ratio, 1e18) - 3e16;
            // 3% -> 5%
        } else if (ratio < 5e17) {
            spreadValue = IporMath.division(5e17 * ratio, 1e18) - 15e16;
            // 5% -> 10%
        } else if (ratio < 8e17) {
            spreadValue = IporMath.division(333333333333333333 * ratio, 1e18) - 66666666666666666;
            // 10% -> 20%
        } else if (ratio < 1e18) {
            spreadValue = IporMath.division(5e17 * ratio, 1e18) - 2e17;
            // 20% -> 30%
        } else {
            spreadValue = 3 * 1e17;
            // 30%
        }
    }
}
