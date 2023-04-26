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

    function saveWeightedNotional28Days(
        StorageId storageId,
        SpreadTypes.WeightedNotional28DaysMemory memory weightedNotional28Days
    ) internal {
        unchecked {
            weightedNotional28Days.weightedNotionalPayFixed =
                weightedNotional28Days.weightedNotionalPayFixed /
                1e18;

            weightedNotional28Days.weightedNotionalReceiveFixed =
                weightedNotional28Days.weightedNotionalReceiveFixed /
                1e18;
        }
        console2.log("weightedNotional28Days.weightedNotionalPayFixed", weightedNotional28Days.weightedNotionalPayFixed);
        console2.log("weightedNotional28Days.weightedNotionalReceiveFixed", weightedNotional28Days.weightedNotionalReceiveFixed);
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

    function getWeightedNotional28Days(StorageId storageId)
        internal
        returns (SpreadTypes.WeightedNotional28DaysMemory memory weightedNotional28Days)
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
            SpreadTypes.WeightedNotional28DaysMemory(
                weightedNotionalPayFixed,
                lastUpdateTimePayFixed,
                weightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed
            );
    }
    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        slot = uint256(storageId) + STORAGE_SLOT_BASE;
    }
}
