// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../libraries/math/IporMath.sol";
import "forge-std/Test.sol";
import "./SpreadTypes.sol";

library SpreadStorageLibs {
    using SafeCast for uint256;
    uint256 private constant STORAGE_SLOT_BASE = 10_000;

    /// Only allowed to append new value to the end of the enum
    enum StorageId {
        Owner,
        AppointedOwner,
        Paused,
        WeightedNotional28DaysDai,
        WeightedNotional28DaysUsdc,
        WeightedNotional28DaysUsdt,
        WeightedNotional60DaysDai,
        WeightedNotional60DaysUsdc,
        WeightedNotional60DaysUsdt,
        WeightedNotional90DaysDai,
        WeightedNotional90DaysUsdc,
        WeightedNotional90DaysUsdt
    }

    struct OwnerStorage {
        address owner;
    }

    struct PausedStorage {
        uint256 value;
    }

    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    function saveWeightedNotional(StorageId storageId, SpreadTypes.WeightedNotionalMemory memory weightedNotional)
        internal
    {
        uint256 weightedNotionalPayFixedTemp;
        uint256 weightedNotionalReceiveFixedTemp;
        unchecked {
            weightedNotionalPayFixedTemp = weightedNotional.weightedNotionalPayFixed / 1e18;

            weightedNotionalReceiveFixedTemp = weightedNotional.weightedNotionalReceiveFixed / 1e18;
        }

        uint96 weightedNotionalPayFixed = weightedNotionalPayFixedTemp.toUint96();
        uint32 lastUpdateTimePayFixed = weightedNotional.lastUpdateTimePayFixed.toUint32();
        uint96 weightedNotionalReceiveFixed = weightedNotionalReceiveFixedTemp.toUint96();
        uint32 lastUpdateTimeReceiveFixed = weightedNotional.lastUpdateTimeReceiveFixed.toUint32();
        uint256 slotAddress = _getStorageSlot(storageId);
        assembly {
            let value := add(
                weightedNotionalPayFixed,
                add(
                    shl(96, lastUpdateTimePayFixed),
                    add(shl(128, weightedNotionalReceiveFixed), shl(224, lastUpdateTimeReceiveFixed))
                )
            )
            sstore(slotAddress, value)
        }
    }

    function getWeightedNotional(StorageId storageId)
        internal
        returns (SpreadTypes.WeightedNotionalMemory memory weightedNotional28Days)
    {
        uint256 weightedNotionalPayFixed;
        uint256 lastUpdateTimePayFixed;
        uint256 weightedNotionalReceiveFixed;
        uint256 lastUpdateTimeReceiveFixed;
        uint256 slotAddress = _getStorageSlot(storageId);
        assembly {
            let slotValue := sload(slotAddress)
            weightedNotionalPayFixed := mul(and(slotValue, 0xFFFFFFFFFFFFFFFFFFFFFFFF), 1000000000000000000)
            lastUpdateTimePayFixed := and(shr(96, slotValue), 0xFFFFFFFF)
            weightedNotionalReceiveFixed := mul(
                and(shr(128, slotValue), 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimeReceiveFixed := and(shr(224, slotValue), 0xFFFFFFFF)
        }

        return
            SpreadTypes.WeightedNotionalMemory({
                weightedNotionalPayFixed: weightedNotionalPayFixed,
                lastUpdateTimePayFixed: lastUpdateTimePayFixed,
                weightedNotionalReceiveFixed: weightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: lastUpdateTimeReceiveFixed,
                storageId: storageId
            });
    }

    function getAllStorageId() internal pure returns (StorageId[] memory storageIds, string[] memory keys) {
        storageIds = new StorageId[](9);
        keys = new string[](9);
        storageIds[0] = StorageId.WeightedNotional28DaysDai;
        keys[0] = "WeightedNotional28DaysDai";
        storageIds[1] = StorageId.WeightedNotional28DaysUsdc;
        keys[1] = "WeightedNotional28DaysUsdc";
        storageIds[2] = StorageId.WeightedNotional28DaysUsdt;
        keys[2] = "WeightedNotional28DaysUsdt";
        storageIds[3] = StorageId.WeightedNotional60DaysDai;
        keys[3] = "WeightedNotional60DaysDai";
        storageIds[4] = StorageId.WeightedNotional60DaysUsdc;
        keys[4] = "WeightedNotional60DaysUsdc";
        storageIds[5] = StorageId.WeightedNotional60DaysUsdt;
        keys[5] = "WeightedNotional60DaysUsdt";
        storageIds[6] = StorageId.WeightedNotional90DaysDai;
        keys[6] = "WeightedNotional90DaysDai";
        storageIds[7] = StorageId.WeightedNotional90DaysUsdc;
        keys[7] = "WeightedNotional90DaysUsdc";
        storageIds[8] = StorageId.WeightedNotional90DaysUsdt;
        keys[8] = "WeightedNotional90DaysUsdt";
    }

    function getOwner() internal view returns (OwnerStorage storage owner) {
        uint256 slotAddress = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := sload(slotAddress)
        }
    }

    function getAppointedOwner() internal view returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slotAddress = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := sload(slotAddress)
        }
    }

    function getPaused() internal view returns (PausedStorage storage paused) {
        uint256 slotAddress = _getStorageSlot(StorageId.Paused);
        assembly {
            paused.slot := sload(slotAddress)
        }
    }

    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        slot = uint256(storageId) + STORAGE_SLOT_BASE;
    }
}
