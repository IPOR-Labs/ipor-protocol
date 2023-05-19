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
        returns (SpreadTypes.TimeWeightedNotionalMemory[] memory timeWeightedNotional, string[] memory timeWeightedNotionalKeys)
    {
        (SpreadStorageLibs.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibs.getAllStorageId();

        for (uint256 i; i < storageIds.length; i++) {
            // todo change to struts
            timeWeightedNotional[i] = SpreadStorageLibs.getWeightedNotional(storageIds[i]);
            timeWeightedNotionalKeys[i] = keys[i];
        }
    }
}
