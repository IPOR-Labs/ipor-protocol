// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library StorageLib {
    uint256  constant STORAGE_SLOT_BASE = 1000000;

    // append only
    enum StorageId {
        PauseGuardian
    }

    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}
