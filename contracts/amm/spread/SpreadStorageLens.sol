// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./SpreadTypes.sol";
import "./ISpreadStorageLens.sol";
import "./SpreadStorageLibs.sol";

contract  SpreadStorageLens is ISpreadStorageLens {
    function getTimeWeightedNotional()
        external
        override
        returns (SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse)
    {
        (SpreadStorageLibs.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibs.getAllStorageId();

        timeWeightedNotionalResponse = new SpreadTypes.TimeWeightedNotionalResponse[](storageIds.length);
        for (uint256 i; i < storageIds.length; i++) {
            timeWeightedNotionalResponse[i].timeWeightedNotional = SpreadStorageLibs.getWeightedNotional(storageIds[i]);
            timeWeightedNotionalResponse[i].key = keys[i];
        }
    }
}
