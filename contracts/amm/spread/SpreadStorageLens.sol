// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./SpreadTypes.sol";
import "./ISpreadStorageLens.sol";
import "./CalculateWeightedNotionalLibs.sol";
import "./SpreadStorageLibs.sol";

contract  SpreadStorageLens is ISpreadStorageLens {
    function getWeightedNotional()
        external
        override
        returns (SpreadTypes.WeightedNotionalMemory[] memory weightedNotional, string[] memory weightedNotionalKeys)
    {
        (SpreadStorageLibs.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibs.getAllStorageId();

        for (uint256 i; i < storageIds.length; i++) {
            // todo change to struts
            weightedNotional[i] = SpreadStorageLibs.getWeightedNotional(storageIds[i]);
            weightedNotionalKeys[i] = keys[i];
        }
    }
}
