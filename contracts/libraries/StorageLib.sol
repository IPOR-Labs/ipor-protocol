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
        AmmSwapsLiquidators,
        AmmPoolsAndAssetManagementRatio,
        AmmPoolsMaxLiquidityPoolBalance,
        AmmPoolsMaxLpAccountContribution,
        AmmPoolsAppointedToRebalance,
        AmmPoolsAutoRebalanceThreshold
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

    /// @dev First key is an asset (pool), second key is an liquidator address in the asset pool,
    /// value is a flag to indicate whether account is a liquidator.
    /// True - account is a liquidator, False - account is not a liquidator.
    struct AmmSwapsLiquidatorsStorage {
        mapping(address => mapping(address => bool)) value;
    }

    /// @dev key - asset address, value - ratio in the asset pool
    struct AmmPoolsAndAssetManagementRatioStorage {
        mapping(address => uint256) value;
    }

    /// @dev key - asset address, value - max liquidity pool balance in the asset pool
    struct AmmPoolsMaxLiquidityPoolBalanceStorage {
        mapping(address => uint256) value;
    }

    /// @dev key - asset address, value - max lp account contribution in the asset pool
    struct AmmPoolsMaxLpAccountContributionStorage {
        mapping(address => uint256) value;
    }

    /// @dev first key - asset address, second key - account address which is allowed to rebalance in the asset pool,
    /// value - flag to indicate whether account is allowed to rebalance. True - allowed, False - not allowed.
    struct AmmPoolsAppointedToRebalanceStorage {
        mapping(address => mapping(address => bool)) value;
    }

    /// @dev key - asset address, value - auto rebalance threshold in the asset pool
    /// @dev The threshold for auto-rebalancing the pool. Value represented without decimals.
    /// Value represents multiplication of 1000.
    struct AmmPoolsAutoRebalanceThresholdStorage {
        mapping(address => uint256) value;
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

    function getAmmSwapsLiquidatorsStorage() internal pure returns (AmmSwapsLiquidatorsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapsLiquidators);
        assembly {
            store.slot := slot
        }
    }

    function getAmmAndAssetManagementRatioStorage()
        internal
        pure
        returns (AmmPoolsAndAssetManagementRatioStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAndAssetManagementRatio);
        assembly {
            store.slot := slot
        }
    }

    function getAmmMaxLiquidityPoolBalanceStorage()
        internal
        pure
        returns (AmmPoolsMaxLiquidityPoolBalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsMaxLiquidityPoolBalance);
        assembly {
            store.slot := slot
        }
    }

    function getAmmMaxLpAccountContributionStorage()
        internal
        pure
        returns (AmmPoolsMaxLpAccountContributionStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsMaxLpAccountContribution);
        assembly {
            store.slot := slot
        }
    }

    function getAmmPoolsAppointedToRebalanceStorage()
        internal
        pure
        returns (AmmPoolsAppointedToRebalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAppointedToRebalance);
        assembly {
            store.slot := slot
        }
    }

    function getAmmAutoRebalanceThresholdStorage()
        internal
        pure
        returns (AmmPoolsAutoRebalanceThresholdStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAutoRebalanceThreshold);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}
