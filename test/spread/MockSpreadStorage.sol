// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/amm/spread/SpreadStorageLibs.sol";
import "../../contracts/amm/spread/SpreadTypes.sol";

contract MockSpreadStorage {
    function saveWeightedNotional(
        SpreadStorageLibs.StorageId storageId,
        SpreadTypes.WeightedNotionalMemory memory weightedNotional28Days
    ) external {
        SpreadStorageLibs.saveWeightedNotional(storageId, weightedNotional28Days);
    }

    function getWeightedNotional(SpreadStorageLibs.StorageId storageId)
    external
    returns (SpreadTypes.WeightedNotionalMemory memory weightedNotional28Days)
    {
        return SpreadStorageLibs.getWeightedNotional(storageId);
    }
}
