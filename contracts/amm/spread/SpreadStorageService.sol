// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../amm/spread/ISpreadStorageLens.sol";
import "../../amm/spread/SpreadTypes.sol";
import "../../amm/spread/SpreadStorageLibs.sol";
import "./ISpreadStorageService.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through SpreadRouter.
contract SpreadStorageService is ISpreadStorageService {
    function updateTimeWeightedNotional(
        SpreadTypes.TimeWeightedNotionalMemory[] calldata timeWeightedNotionalMemories
    ) external override {
        uint256 length = timeWeightedNotionalMemories.length;
        for (uint256 i; i < length; ) {
            SpreadStorageLibs._checkTimeWeightedNotional(timeWeightedNotionalMemories[i].storageId);
            SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
                timeWeightedNotionalMemories[i].storageId,
                timeWeightedNotionalMemories[i]
            );
            unchecked {
                ++i;
            }
        }
    }
}
