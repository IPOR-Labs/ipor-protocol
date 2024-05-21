// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../amm/spread/SpreadTypes.sol";
import "../../amm/spread/SpreadStorageLibs.sol";
import "../../base/events/AmmEventsBaseV1.sol";
import "./ISpreadStorageService.sol";

/// @dev It is not recommended to use service contract directly, should be used only through SpreadRouter.
contract SpreadStorageService is ISpreadStorageService {
    function updateTimeWeightedNotional(
        SpreadTypes.TimeWeightedNotionalMemory[] calldata timeWeightedNotionalMemories
    ) external override {
        uint256 length = timeWeightedNotionalMemories.length;
        for (uint256 i; i < length; ) {
            SpreadStorageLibs.checkTimeWeightedNotional(timeWeightedNotionalMemories[i].storageId);
            SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(
                timeWeightedNotionalMemories[i].storageId,
                timeWeightedNotionalMemories[i]
            );

            emit AmmEventsBaseV1.SpreadTimeWeightedNotionalChanged({
                timeWeightedNotionalPayFixed: timeWeightedNotionalMemories[i].timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: timeWeightedNotionalMemories[i].lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalMemories[i].timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: timeWeightedNotionalMemories[i].lastUpdateTimeReceiveFixed,
                storageId: uint256(timeWeightedNotionalMemories[i].storageId)
            });

            unchecked {
                ++i;
            }
        }
    }
}
