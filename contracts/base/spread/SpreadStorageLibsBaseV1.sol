// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/AmmErrors.sol";
import "../types/SpreadTypesBaseV1.sol";

/// @title Spread storage library
library SpreadStorageLibsBaseV1 {
    using SafeCast for uint256;
    uint256 private constant STORAGE_SLOT_BASE = 10_000;

    /// Only allowed to append new value to the end of the enum
    enum StorageId {
        // WeightedNotionalStorage
        TimeWeightedNotional28Days,
        TimeWeightedNotional60Days,
        TimeWeightedNotional90Days
    }

    /// @notice Saves time weighted notional for a specific asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    /// @param timeWeightedNotional The time weighted notional to save
    function saveTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId,
        SpreadTypesBaseV1.TimeWeightedNotionalMemory memory timeWeightedNotional
    ) internal {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);

        uint256 timeWeightedNotionalPayFixedTemp;
        uint256 timeWeightedNotionalReceiveFixedTemp;

        unchecked {
            timeWeightedNotionalPayFixedTemp = timeWeightedNotional.timeWeightedNotionalPayFixed / 1e18;

            timeWeightedNotionalReceiveFixedTemp = timeWeightedNotional.timeWeightedNotionalReceiveFixed / 1e18;
        }

        uint96 timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixedTemp.toUint96();
        uint32 lastUpdateTimePayFixed = timeWeightedNotional.lastUpdateTimePayFixed.toUint32();
        uint96 timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedTemp.toUint96();
        uint32 lastUpdateTimeReceiveFixed = timeWeightedNotional.lastUpdateTimeReceiveFixed.toUint32();
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);

        assembly {
            let value := add(
                timeWeightedNotionalPayFixed,
                add(
                    shl(96, lastUpdateTimePayFixed),
                    add(shl(128, timeWeightedNotionalReceiveFixed), shl(224, lastUpdateTimeReceiveFixed))
                )
            )
            sstore(slotAddress, value)
        }
    }

    /// @notice Gets the time-weighted notional for a specific storage ID representing an asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    function getTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId
    ) internal view returns (SpreadTypesBaseV1.TimeWeightedNotionalMemory memory weightedNotional28Days) {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);

        uint256 timeWeightedNotionalPayFixed;
        uint256 lastUpdateTimePayFixed;
        uint256 timeWeightedNotionalReceiveFixed;
        uint256 lastUpdateTimeReceiveFixed;
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);

        assembly {
            let slotValue := sload(slotAddress)
            timeWeightedNotionalPayFixed := mul(and(slotValue, 0xFFFFFFFFFFFFFFFFFFFFFFFF), 1000000000000000000)
            lastUpdateTimePayFixed := and(shr(96, slotValue), 0xFFFFFFFF)
            timeWeightedNotionalReceiveFixed := mul(
                and(shr(128, slotValue), 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimeReceiveFixed := and(shr(224, slotValue), 0xFFFFFFFF)
        }

        return
            SpreadTypesBaseV1.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: lastUpdateTimeReceiveFixed,
                storageId: timeWeightedNotionalStorageId
            });
    }

    /// @notice Gets all time weighted notional storage IDs
    function getAllStorageId() internal pure returns (StorageId[] memory storageIds, string[] memory keys) {
        storageIds = new StorageId[](3);
        keys = new string[](3);
        storageIds[0] = StorageId.TimeWeightedNotional28Days;
        keys[0] = "TimeWeightedNotional28Days";
        storageIds[1] = StorageId.TimeWeightedNotional60Days;
        keys[1] = "TimeWeightedNotional60Days";
        storageIds[2] = StorageId.TimeWeightedNotional90Days;
        keys[2] = "TimeWeightedNotional90Days";
    }

    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        slot = uint256(storageId) + STORAGE_SLOT_BASE;
    }

    function _checkTimeWeightedNotional(StorageId storageId) internal pure {
        require(
            storageId == StorageId.TimeWeightedNotional28Days ||
                storageId == StorageId.TimeWeightedNotional60Days ||
                storageId == StorageId.TimeWeightedNotional90Days,
            AmmErrors.STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL
        );
    }
}
