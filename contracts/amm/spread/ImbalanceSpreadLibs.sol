// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./CalculateWeightedNotionalLibs.sol";

library ImbalanceSpreadLibs {
    /// @notice Dto for the Weighted Notional
    struct SpreadInputData {
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPool;
        /// @notice Swap's notional balance for Pay Fixed leg
        uint256 totalNotionalPayFixed;
        /// @notice Swap's notional balance for Receive Fixed leg
        uint256 totalNotionalReceiveFixed;
        uint256 swapNotional;
        uint256 maxLeverage;
        uint256 maxLpUtilizationPerLegRate;
        uint256[] maturities;
        SpreadStorageLibs.StorageId[] storageIds;
        SpreadStorageLibs.StorageId storageId;
    }

    function calculatePayFixedSpread(SpreadInputData memory inputData) internal returns (uint256 spreadValue) {
        uint256 lpDepth = CalculateWeightedNotionalLibs.calculateLpDepth(
            inputData.liquidityPool,
            inputData.totalCollateralPayFixed,
            inputData.totalCollateralReceiveFixed
        );

        uint256 notionalDepth = IporMath.division(
            lpDepth * inputData.maxLeverage * inputData.maxLpUtilizationPerLegRate,
            1e36
        );

        (uint256 oldWeightedNotionalPayFixed, uint256 weightedNotionalReceiveFixed) = CalculateWeightedNotionalLibs
            .getWeightedNotional(inputData.storageIds, inputData.maturities);
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

    function calculateReceiveFixedSpread(SpreadInputData memory inputData) internal returns (uint256 spreadValue) {
        uint256 lpDepth = CalculateWeightedNotionalLibs.calculateLpDepth(
            inputData.liquidityPool,
            inputData.totalCollateralPayFixed,
            inputData.totalCollateralReceiveFixed
        );

        uint256 notionalDepth = IporMath.division(
            lpDepth * inputData.maxLeverage * inputData.maxLpUtilizationPerLegRate,
            1e36
        );

        (uint256 weightedNotionalPayFixed, uint256 oldWeightedNotionalReceiveFixed) = CalculateWeightedNotionalLibs
            .getWeightedNotional(inputData.storageIds, inputData.maturities);
        uint256 newWeightedNotionalReceiveFixed = oldWeightedNotionalReceiveFixed + inputData.swapNotional;
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

    function spreadFunctionConfig() public pure returns (uint256[] memory) {
        uint256[] memory config = new uint256[](21);
        config[0] = INTERVAL_ONE;
        config[1] = INTERVAL_TWO;
        config[2] = INTERVAL_THREE;
        config[3] = INTERVAL_FOUR;
        config[4] = INTERVAL_FIVE;
        config[5] = INTERVAL_SIX;
        config[6] = INTERVAL_SEVEN;
        config[7] = SLOPE_ONE;
        config[8] = BASE_ONE;
        config[9] = SLOPE_TWO;
        config[10] = BASE_TWO;
        config[11] = SLOPE_THREE;
        config[12] = BASE_THREE;
        config[13] = SLOPE_FOUR;
        config[14] = BASE_FOUR;
        config[15] = SLOPE_FIVE;
        config[16] = BASE_FIVE;
        config[17] = SLOPE_SIX;
        config[18] = BASE_SIX;
        config[19] = SLOPE_SEVEN;
        config[20] = BASE_SEVEN;
        return config;
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
