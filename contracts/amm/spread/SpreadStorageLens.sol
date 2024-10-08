// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../../amm/spread/ISpreadStorageLens.sol";
import "../../amm/spread/SpreadTypes.sol";
import "../../amm/spread/SpreadStorageLibs.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through SpreadRouter.
contract SpreadStorageLens is ISpreadStorageLens {
    function getTimeWeightedNotional()
        external
        view
        override
        returns (SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse)
    {
        (SpreadStorageLibs.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibs.getAllStorageId();
        uint256 storageIdLength = storageIds.length;
        timeWeightedNotionalResponse = new SpreadTypes.TimeWeightedNotionalResponse[](storageIdLength);

        for (uint256 i; i != storageIdLength; ) {
            timeWeightedNotionalResponse[i].timeWeightedNotional = SpreadStorageLibs
                .getTimeWeightedNotionalForAssetAndTenor(storageIds[i]);
            timeWeightedNotionalResponse[i].key = keys[i];
            unchecked {
                ++i;
            }
        }
    }
}
