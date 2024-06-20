// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {CalculateTimeWeightedNotionalLibsBaseV1} from "./CalculateTimeWeightedNotionalLibsBaseV1.sol";
import {SpreadStorageLibsBaseV1} from "../spread/SpreadStorageLibsBaseV1.sol";
import {IporMath} from "../../libraries/math/IporMath.sol";
import {SpreadInputData} from "../interfaces/DemandSpreadTypesBaseV1.sol";

library DemandSpreadStableLibsBaseV1 {
    uint256 internal constant INTERVAL_ONE = 2e17;
    uint256 internal constant INTERVAL_TWO = 5e17;
    uint256 internal constant INTERVAL_THREE = 1e18;

    uint256 internal constant SLOPE_ONE = 5e16;
    uint256 internal constant BASE_ONE = 0;

    uint256 internal constant SLOPE_TWO = 133333333333333333;
    uint256 internal constant BASE_TWO = 16666666666666667;

    uint256 internal constant SLOPE_THREE = 5e17;
    uint256 internal constant BASE_THREE = 2e17;

    /// @notice Gets the spread function configuration.
    function spreadFunctionConfig() internal pure returns (uint256[] memory) {
        uint256[] memory config = new uint256[](21);
        config[0] = INTERVAL_ONE;
        config[1] = INTERVAL_TWO;
        config[2] = INTERVAL_THREE;
        config[3] = SLOPE_ONE;
        config[4] = BASE_ONE;
        config[5] = SLOPE_TWO;
        config[6] = BASE_TWO;
        config[7] = SLOPE_THREE;
        config[8] = BASE_THREE;
        return config;
    }

    /// @notice Calculates the spread value for the pay-fixed side based on the provided input data.
    /// @param inputData The input data required for the calculation, including liquidity pool information and collateral amounts.
    /// @return spreadValue The calculated spread value for the pay-fixed side.
    function calculatePayFixedSpread(SpreadInputData memory inputData) internal view returns (uint256 spreadValue) {
        uint256 lpDepth = CalculateTimeWeightedNotionalLibsBaseV1.calculateLpDepth(
            inputData.liquidityPoolBalance,
            inputData.totalCollateralPayFixed,
            inputData.totalCollateralReceiveFixed
        );

        /// @dev demandSpreadFactor is without decimals.
        uint256 notionalDepth = lpDepth * inputData.demandSpreadFactor;

        (
            uint256 oldWeightedNotionalPayFixed,
            uint256 timeWeightedNotionalReceiveFixed
        ) = CalculateTimeWeightedNotionalLibsBaseV1.getTimeWeightedNotional(
                inputData.timeWeightedNotionalStorageIds,
                inputData.tenorsInSeconds,
                inputData.selectedTenorInSeconds
            );

        uint256 newWeightedNotionalPayFixed = oldWeightedNotionalPayFixed + inputData.swapNotional;

        if (newWeightedNotionalPayFixed > timeWeightedNotionalReceiveFixed) {
            uint256 oldSpread;

            if (oldWeightedNotionalPayFixed > timeWeightedNotionalReceiveFixed) {
                oldSpread = calculateSpreadFunction(
                    notionalDepth,
                    oldWeightedNotionalPayFixed - timeWeightedNotionalReceiveFixed
                );
            }

            uint256 newSpread = calculateSpreadFunction(
                notionalDepth,
                newWeightedNotionalPayFixed - timeWeightedNotionalReceiveFixed
            );

            spreadValue = IporMath.division(oldSpread + newSpread, 2);
        } else {
            spreadValue = 0;
        }
    }

    /// @notice Calculates the spread value for the receive-fixed side based on the provided input data.
    /// @param inputData The input data required for the calculation, including liquidity pool information and collateral amounts.
    /// @return spreadValue The calculated spread value for the receive-fixed side.
    function calculateReceiveFixedSpread(SpreadInputData memory inputData) internal view returns (uint256 spreadValue) {
        uint256 lpDepth = CalculateTimeWeightedNotionalLibsBaseV1.calculateLpDepth(
            inputData.liquidityPoolBalance,
            inputData.totalCollateralPayFixed,
            inputData.totalCollateralReceiveFixed
        );

        /// @dev demandSpreadFactor is without decimals.
        uint256 notionalDepth = lpDepth * inputData.demandSpreadFactor;

        (
            uint256 timeWeightedNotionalPayFixed,
            uint256 oldWeightedNotionalReceiveFixed
        ) = CalculateTimeWeightedNotionalLibsBaseV1.getTimeWeightedNotional(
                inputData.timeWeightedNotionalStorageIds,
                inputData.tenorsInSeconds,
                inputData.selectedTenorInSeconds
            );

        uint256 newWeightedNotionalReceiveFixed = oldWeightedNotionalReceiveFixed + inputData.swapNotional;

        if (newWeightedNotionalReceiveFixed > timeWeightedNotionalPayFixed) {
            uint256 oldSpread;

            if (oldWeightedNotionalReceiveFixed > timeWeightedNotionalPayFixed) {
                oldSpread = calculateSpreadFunction(
                    notionalDepth,
                    oldWeightedNotionalReceiveFixed - timeWeightedNotionalPayFixed
                );
            }

            uint256 newSpread = calculateSpreadFunction(
                notionalDepth,
                newWeightedNotionalReceiveFixed - timeWeightedNotionalPayFixed
            );

            spreadValue = IporMath.division(oldSpread + newSpread, 2);
        } else {
            spreadValue = 0;
        }
    }

    /// @notice Calculates the spread value based on the given maximum notional and weighted notional.
    /// @param maxNotional The maximum notional value determined by lpDepth and demandSpreadFactor from Risk Oracle
    /// @param weightedNotional The weighted notional value used in the spread calculation.
    /// @return spreadValue The calculated spread value based on the given inputs.
    /// @dev maxNotional = lpDepth * demandSpreadFactor
    function calculateSpreadFunction(
        uint256 maxNotional,
        uint256 weightedNotional
    ) internal pure returns (uint256 spreadValue) {
        uint256 ratio = IporMath.division(weightedNotional * 1e18, maxNotional);
        if (ratio < INTERVAL_ONE) {
            spreadValue = IporMath.division(SLOPE_ONE * ratio, 1e18) - BASE_ONE;
            /// @dev spreadValue in range < 0%, 1% )
        } else if (ratio < INTERVAL_TWO) {
            spreadValue = IporMath.division(SLOPE_TWO * ratio, 1e18) - BASE_TWO;
            /// @dev spreadValue in range < 1%, 5% )
        } else if (ratio < INTERVAL_THREE) {
            spreadValue = IporMath.division(SLOPE_THREE * ratio, 1e18) - BASE_THREE;
            /// @dev spreadValue in range < 5%, 30% )
        } else {
            spreadValue = 3 * 1e17;
            /// @dev spreadValue is equal to 30%
        }
    }
}
