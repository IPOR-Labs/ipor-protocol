// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../libraries/math/IporMath.sol";
import "forge-std/Test.sol";
import "./SpreadTypes.sol";

library SpreadStorageLibs {
    using SafeCast for uint256;
    uint256 private constant STORAGE_SLOT_BASE = 10000;

    /// Only allowed to append new value to the end of the enum
    enum StorageId {
        WeightedNotional28DaysDai,
        WeightedNotional28DaysUsdc,
        WeightedNotional28DaysUsdt,
        WeightedNotional90DaysDai,
        WeightedNotional90DaysUsdc,
        WeightedNotional90DaysUsdt
    }

    function saveWeightedNotional(
        StorageId storageId,
        SpreadTypes.WeightedNotionalMemory memory weightedNotional28Days
    ) internal {
        unchecked {
            weightedNotional28Days.weightedNotionalPayFixed =
                weightedNotional28Days.weightedNotionalPayFixed /
                1e18;

            weightedNotional28Days.weightedNotionalReceiveFixed =
                weightedNotional28Days.weightedNotionalReceiveFixed /
                1e18;
        }
        uint96 weightedNotionalPayFixed = weightedNotional28Days
            .weightedNotionalPayFixed
            .toUint96();
        uint32 lastUpdateTimePayFixed = weightedNotional28Days.lastUpdateTimePayFixed.toUint32();
        uint96 weightedNotionalReceiveFixed = weightedNotional28Days
            .weightedNotionalReceiveFixed
            .toUint96();
        uint32 lastUpdateTimeReceiveFixed = weightedNotional28Days
            .lastUpdateTimeReceiveFixed
            .toUint32();
        uint256 slotAddress = _getStorageSlot(storageId);
        assembly {
            let value := add(
                weightedNotionalPayFixed,
                add(
                    shl(96, lastUpdateTimePayFixed),
                    add(
                        shl(128, weightedNotionalReceiveFixed),
                        shl(224, lastUpdateTimeReceiveFixed)
                    )
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
            weightedNotionalPayFixed := mul(
                and(slotValue, 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimePayFixed := and(shr(96, slotValue), 0xFFFFFFFF)
            weightedNotionalReceiveFixed := mul(
                and(shr(128, slotValue), 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimeReceiveFixed := and(shr(224, slotValue), 0xFFFFFFFF)
        }

        return
            SpreadTypes.WeightedNotionalMemory(
                weightedNotionalPayFixed,
                lastUpdateTimePayFixed,
                weightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed,
                storageId
            );
    }

    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {

        slot = uint256(storageId) + STORAGE_SLOT_BASE;
//        slot = uint256(keccak256("ipor.io.storage.spread"));
    }
}
