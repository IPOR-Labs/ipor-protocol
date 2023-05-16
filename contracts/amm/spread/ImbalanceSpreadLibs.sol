// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./CalculateWeightedNotionalLibs.sol";

library ImbalanceSpreadLibs {
    /// @notice Dto for the Weighted Notional
    struct SpreadInputData {
        IporTypes.SwapsBalanceMemory accruedBalance;
        uint256 swapNotional;
        uint256 maxLeverage;
        uint256 maxLpUtilizationPerLegRate;
        SpreadStorageLibs.StorageId[] storageIds;
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
        ) = CalculateWeightedNotionalLibs.getWeightedNotional(inputData.storageIds);
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
        ) = CalculateWeightedNotionalLibs.getWeightedNotional(inputData.storageIds);
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

    uint256 internal constant INTERVAL_ONE = 1e17;
    uint256 internal constant INTERVAL_TWO = 2e17;
    uint256 internal constant INTERVAL_THREE = 3e17;
    uint256 internal constant INTERVAL_FOUR = 4e17;
    uint256 internal constant INTERVAL_FIVE = 5e17;
    uint256 internal constant INTERVAL_SIX = 8e17;
    uint256 internal constant INTERVAL_SEVEN = 1e18;

    uint256 internal constant SLOPE_ONE = 5e16;
    uint256 internal constant BASE_ONE = 1e18;

    uint256 internal constant SLOPE_TWO = 1e17;
    uint256 internal constant BASE_TWO = 5e15;

    uint256 internal constant SLOPE_THREE = 15e16;
    uint256 internal constant BASE_THREE = 15e15;

    uint256 internal constant SLOPE_FOUR = 2e17;
    uint256 internal constant BASE_FOUR = 3e16;

    uint256 internal constant SLOPE_FIVE = 5e17;
    uint256 internal constant BASE_FIVE = 15e16;

    uint256 internal constant SLOPE_SIX = 333333333333333333;
    uint256 internal constant BASE_SIX = 66666666666666666;

    uint256 internal constant SLOPE_SEVEN = 5e17;
    uint256 internal constant BASE_SEVEN = 2e17;

    function SpreadFunctionConfig() public pure returns (uint256[20] memory) {
        return [
            INTERVAL_ONE,
            INTERVAL_TWO,
            INTERVAL_THREE,
            INTERVAL_FOUR,
            INTERVAL_FIVE,
            INTERVAL_SIX,
            INTERVAL_SEVEN,
            SLOPE_ONE,
            BASE_ONE,
            SLOPE_TWO,
            BASE_TWO,
            SLOPE_THREE,
            BASE_THREE,
            SLOPE_FOUR,
            BASE_FOUR,
            SLOPE_FIVE,
            BASE_FIVE,
            SLOPE_SIX,
            BASE_SIX,
            SLOPE_SEVEN,
            BASE_SEVEN
        ];
    }

    function calculateSpreadFunction(
        uint256 maxNotional, // lpDepth * leverage * maxUtilisation
        uint256 weightedNotional
    ) public view returns (uint256 spreadValue) {
        uint256 ratio = IporMath.division(weightedNotional * 1e18, maxNotional);
        if (ratio < 1e17) {
            spreadValue = IporMath.division(SLOPE_ONE * ratio, BASE_ONE);
            // 0% -> 0.5%
        } else if (ratio < 2e17) {
            spreadValue = IporMath.division(SLOPE_TWO * ratio, 1e18) - BASE_TWO;
            // 0.5% -> 1.5%
        } else if (ratio < 3e17) {
            spreadValue = IporMath.division(SLOPE_THREE * ratio, 1e18) - BASE_THREE;
            // 1.5% -> 3%
        } else if (ratio < 4e17) {
            spreadValue = IporMath.division(SLOPE_FOUR * ratio, 1e18) - BASE_FOUR;
            // 3% -> 5%
        } else if (ratio < 5e17) {
            spreadValue = IporMath.division(SLOPE_FIVE * ratio, 1e18) - BASE_FIVE;
            // 5% -> 10%
        } else if (ratio < 8e17) {
            spreadValue = IporMath.division(SLOPE_SIX * ratio, 1e18) - BASE_SIX;
            // 10% -> 20%
        } else if (ratio < 1e18) {
            spreadValue = IporMath.division(SLOPE_SEVEN * ratio, 1e18) - BASE_SEVEN;
            // 20% -> 30%
        } else {
            spreadValue = 3 * 1e17;
            // 30%
        }
    }
}
