// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./SpreadTypes.sol";
import "./ISpreadStorageLens.sol";
import "./SpreadStorageLibs.sol";

contract SpreadStorageLens is ISpreadStorageLens {
    function getTimeWeightedNotional()
        external
        override
        returns (SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse)
    {
        (SpreadStorageLibs.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibs.getAllStorageId();
        uint256 storageIdLength = storageIds.length;
        timeWeightedNotionalResponse = new SpreadTypes.TimeWeightedNotionalResponse[](storageIdLength);
        for (uint256 i; i != storageIdLength; ) {
            timeWeightedNotionalResponse[i].timeWeightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
                storageIds[i]
            );
            timeWeightedNotionalResponse[i].key = keys[i];
            unchecked {
                ++i;
            }
        }
    }
}
