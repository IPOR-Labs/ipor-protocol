// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/amm/spread/SpreadStorageLibs.sol";
import "../../contracts/amm/spread/SpreadTypes.sol";

contract MockSpreadStorage {
    function saveWeightedNotional28Days(
        SpreadStorageLibs.StorageId storageId,
        SpreadTypes.WeightedNotional28DaysMemory memory weightedNotional28Days
    ) external {
        SpreadStorageLibs.saveWeightedNotional28Days(storageId, weightedNotional28Days);
    }

    function getWeightedNotional28Days(SpreadStorageLibs.StorageId storageId)
    external
    returns (SpreadTypes.WeightedNotional28DaysMemory memory weightedNotional28Days)
    {
        return SpreadStorageLibs.getWeightedNotional28Days(storageId);
    }
}
