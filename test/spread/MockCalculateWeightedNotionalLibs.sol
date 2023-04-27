// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/amm/spread/CalculateWeightedNotionalLibs.sol";
import "../../contracts/amm/spread/SpreadStorageLibs.sol";

contract MockCalculateWeightedNotionalLibs {
    function calculateLpDepth(
        uint256 lpBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) external view returns (uint256 lpDepth) {
        return
            CalculateWeightedNotionalLibs.calculateLpDepth(
                lpBalance,
                totalCollateralPayFixed,
                totalCollateralReceiveFixed
            );
    }

    function calculateWeightedNotional(
        uint256 weightedNotional,
        uint256 timeFromLastUpdate,
        uint256 maturity
    ) external view returns (uint256) {
        return
            CalculateWeightedNotionalLibs.calculateWeightedNotional(
                weightedNotional,
                timeFromLastUpdate,
                maturity
            );
    }

    function updateWeightedNotionalReceiveFixed28Days(
        SpreadTypes.WeightedNotionalMemory memory weightedNotional,
        uint256 newSwapNotional,
        uint256 maturity
    ) external {
        CalculateWeightedNotionalLibs.updateWeightedNotionalReceiveFixed(
            weightedNotional,
            newSwapNotional,
            maturity
        );
    }

    function getWeightedNotional(SpreadStorageLibs.StorageId storageId)
        external
        returns (SpreadTypes.WeightedNotionalMemory memory weightedNotional28Days)
    {
        return SpreadStorageLibs.getWeightedNotional(storageId);
    }

    function saveWeightedNotional(SpreadTypes.WeightedNotionalMemory memory weightedNotional, SpreadStorageLibs.StorageId storageId)
        external
    {
        return SpreadStorageLibs.saveWeightedNotional(storageId, weightedNotional);
    }

    function updateWeightedNotionalPayFixed(
        SpreadTypes.WeightedNotionalMemory memory weightedNotional,
        uint256 newSwapNotional,
        uint256 maturity
    ) external {
        CalculateWeightedNotionalLibs.updateWeightedNotionalPayFixed(
            weightedNotional,
            newSwapNotional,
            maturity
        );
    }

    function getWeightedNotional(
        SpreadStorageLibs.StorageId storageId28Days,
        SpreadStorageLibs.StorageId storageId90Days
    ) external returns (uint256 weightedNotionalPayFixed, uint256 weightedNotionalReceiveFixed) {
        return CalculateWeightedNotionalLibs.getWeightedNotional(storageId28Days, storageId90Days);
    }
}
