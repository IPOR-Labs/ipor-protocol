// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./SpreadTypes.sol";
import "./SpreadStorageLibs.sol";
import "../../libraries/math/IporMath.sol";

library CalculateWeightedNotionalLibs {
    /// @notice calculate amm lp depth
    /// @param lpBalance lp balance
    /// @param totalCollateralPayFixed total collateral pay fixed
    /// @param totalCollateralReceiveFixed total collateral receive fixed
    function calculateLpDepth(
        uint256 lpBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) internal view returns (uint256 lpDepth) {
        if (totalCollateralPayFixed >= totalCollateralReceiveFixed) {
            lpDepth = lpBalance + totalCollateralReceiveFixed - totalCollateralPayFixed;
        } else {
            lpDepth = lpBalance + totalCollateralPayFixed - totalCollateralReceiveFixed;
        }
    }

    /// @notice calculate weighted notional
    /// @param weightedNotional weighted notional value
    /// @param timeFromLastUpdate time from last update in seconds
    /// @param maturity maturity in seconds
    function calculateWeightedNotional(
        uint256 weightedNotional,
        uint256 timeFromLastUpdate,
        uint256 maturity
    ) internal view returns (uint256) {
        if (timeFromLastUpdate >= maturity) {
            return 0;
        }
        uint256 newWeightedNotional = IporMath.divisionWithoutRound(
            weightedNotional * (maturity - timeFromLastUpdate),
            maturity
        );
        return newWeightedNotional;
    }

    function updateWeightedNotionalReceiveFixed(
        SpreadTypes.WeightedNotionalMemory memory weightedNotional,
        uint256 newSwapNotional,
        uint256 maturity
    ) internal {
        if (weightedNotional.weightedNotionalReceiveFixed == 0) {
            weightedNotional.weightedNotionalReceiveFixed = calculateWeightedNotional(
                newSwapNotional,
                0,
                maturity
            );
        } else {
            uint256 oldWeightedNotionalReceiveFixed = calculateWeightedNotional(
                weightedNotional.weightedNotionalReceiveFixed,
                block.timestamp - weightedNotional.lastUpdateTimeReceiveFixed,
                maturity
            );
            weightedNotional.weightedNotionalReceiveFixed =
                newSwapNotional +
                oldWeightedNotionalReceiveFixed;
        }
        weightedNotional.lastUpdateTimeReceiveFixed = block.timestamp;
        SpreadStorageLibs.saveWeightedNotional(weightedNotional.storageId, weightedNotional);
    }

    function updateWeightedNotionalPayFixed(
        SpreadTypes.WeightedNotionalMemory memory weightedNotional,
        uint256 newSwapNotional,
        uint256 maturity
    ) internal {
        if (weightedNotional.weightedNotionalPayFixed == 0) {
            weightedNotional.weightedNotionalPayFixed = calculateWeightedNotional(
                newSwapNotional,
                0,
                maturity
            );
        } else {
            uint256 oldWeightedNotionalPayFixed = calculateWeightedNotional(
                weightedNotional.weightedNotionalPayFixed,
                block.timestamp - weightedNotional.lastUpdateTimePayFixed,
                maturity
            );
            weightedNotional.weightedNotionalPayFixed =
                newSwapNotional +
                oldWeightedNotionalPayFixed;
        }
        weightedNotional.lastUpdateTimePayFixed = block.timestamp;
        SpreadStorageLibs.saveWeightedNotional(weightedNotional.storageId, weightedNotional);
    }

    function getWeightedNotional(
        SpreadStorageLibs.StorageId storageId28Days,
        SpreadStorageLibs.StorageId storageId90Days
    ) internal returns (uint256 weightedNotionalPayFixed, uint256 weightedNotionalReceiveFixed) {
        SpreadTypes.WeightedNotionalMemory memory weightedNotional28days = SpreadStorageLibs
            .getWeightedNotional(storageId28Days);
        SpreadTypes.WeightedNotionalMemory memory weightedNotional90days = SpreadStorageLibs
            .getWeightedNotional(storageId90Days);

        weightedNotionalPayFixed =
            calculateWeightedNotional(
                weightedNotional28days.weightedNotionalPayFixed,
                block.timestamp - weightedNotional28days.lastUpdateTimePayFixed,
                28 days
            ) +
            calculateWeightedNotional(
                weightedNotional90days.weightedNotionalPayFixed,
                block.timestamp - weightedNotional90days.lastUpdateTimePayFixed,
                90 days
            );
        weightedNotionalReceiveFixed = calculateWeightedNotional(
            weightedNotional28days.weightedNotionalReceiveFixed,
            block.timestamp - weightedNotional28days.lastUpdateTimeReceiveFixed,
            28 days
        ) + calculateWeightedNotional(
            weightedNotional90days.weightedNotionalReceiveFixed,
            block.timestamp - weightedNotional90days.lastUpdateTimeReceiveFixed,
            90 days
        );
    }
}
