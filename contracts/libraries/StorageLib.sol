// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Storage ID's associated with the IPOR Protocol Router.
library StorageLib {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardian,
        /// @dev Mapping of asset address to its ratio.
        AmmAndAssetManagementRatio,
        AmmMaxLiquidityPoolBalance,
        AmmMaxLpAccountContribution,
        AmmAppointedToRebalance,
        AmmTreasury,
        AmmTreasuryManager,
        AmmCharlieTreasury,
        AmmCharlieTreasuryManager,
        /// @dev Mapping of liquidator address and its flag to indicate whether it is enabled.
        AmmSwapLiquidators
    }

    struct OwnerStorage {
        address owner;
    }

    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    struct PausedStorage {
        uint256 value;
    }

    struct AmmAndAssetManagementRatioStorage {
        mapping(address => uint256) value;
    }

    struct AmmMaxLiquidityPoolBalanceStorage {
        uint256 value;
    }

    struct AmmMaxLpAccountContributionStorage {
        uint256 value;
    }

    struct AmmAppointedToRebalanceStorage {
        address value;
    }

    struct AmmTreasuryStorage {
        address value;
    }

    struct AmmTreasuryManagerStorage {
        address value;
    }

    struct AmmCharlieTreasuryStorage {
        address value;
    }

    struct AmmCharlieTreasuryManagerStorage {
        address value;
    }

    struct AmmSwapLiquidatorsStorage {
        mapping(address => bool) value;
    }

    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    function getPaused() internal pure returns (PausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.Paused);
        assembly {
            paused.slot := slot
        }
    }

    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    function getAmmAndAssetManagementRatioStorage()
        internal
        pure
        returns (AmmAndAssetManagementRatioStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmAndAssetManagementRatio);
        assembly {
            store.slot := slot
        }
    }

    function getAmmMaxLiquidityPoolBalanceStorage()
        internal
        pure
        returns (AmmMaxLiquidityPoolBalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmMaxLiquidityPoolBalance);
        assembly {
            store.slot := slot
        }
    }

    function getAmmMaxLpAccountContributionStorage()
        internal
        pure
        returns (AmmMaxLpAccountContributionStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmMaxLpAccountContribution);
        assembly {
            store.slot := slot
        }
    }

    function getAmmAppointedToRebalanceStorage() internal pure returns (AmmAppointedToRebalanceStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmAppointedToRebalance);
        assembly {
            store.slot := slot
        }
    }

    function getAmmTreasuryStorage() internal pure returns (AmmTreasuryStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmTreasury);
        assembly {
            store.slot := slot
        }
    }

    function getAmmTreasuryManagerStorage() internal pure returns (AmmTreasuryManagerStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmTreasuryManager);
        assembly {
            store.slot := slot
        }
    }

    function getAmmCharlieTreasuryStorage() internal pure returns (AmmCharlieTreasuryStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmCharlieTreasury);
        assembly {
            store.slot := slot
        }
    }

    function getAmmCharlieTreasuryManagerStorage()
        internal
        pure
        returns (AmmCharlieTreasuryManagerStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmCharlieTreasuryManager);
        assembly {
            store.slot := slot
        }
    }

    function getAmmSwapLiquidatorsStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapLiquidators);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}
