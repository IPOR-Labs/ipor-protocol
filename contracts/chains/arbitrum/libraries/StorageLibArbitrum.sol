// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title Storage ID's associated with the IPOR Protocol Router.
library StorageLibArbitrum {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardian,
        ReentrancyStatus,
        RouterFunctionPaused,
        AmmSwapsLiquidators,
        AmmPoolsAppointedToRebalance,
        AmmPoolsParams,
        MessageSigner, /// @dev The address of the IPOR Message Signer.
        AssetLensData, /// @dev Mapping of asset address to asset lens data.
        AssetGovernancePoolConfig, /// @dev Mapping of asset address to asset governance data.
        AssetServices /// @dev Mapping of asset address to set of services per pool.
    }

    /// @notice Struct for one asset which contains services for a specific asset pool.
    struct AssetServicesValue {
        address ammPoolsService;
        address ammOpenSwapService;
        address ammCloseSwapService;
    }

    /// @notice Struct which contains services for a specific asset pool.
    struct AssetServicesStorage {
        mapping(address asset => AssetServicesValue) value;
    }

    /// @notice Struct for one asset combining all data required for lens services related to a specific asset pool.
    struct AssetLensDataValue {
        uint8 decimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address ammVault;
        address spread;
    }

    /// @notice Struct combining all data required for lens services related to a specific asset pool.
    struct AssetLensDataStorage {
        mapping(address asset => AssetLensDataValue) value;
    }

    /// @notice Struct which contains governance configuration for a specific asset pool.
    struct AssetGovernancePoolConfigValue {
        uint8 decimals;
        address ammStorage;
        address ammTreasury;
        address ammVault;
        address ammPoolsTreasury;
        address ammPoolsTreasuryManager;
        address ammCharlieTreasury;
        address ammCharlieTreasuryManager;
    }

    /// @notice Struct which contains governance configuration for a specific asset pool.
    struct AssetGovernancePoolConfigStorage {
        mapping(address asset => AssetGovernancePoolConfigValue) value;
    }

    struct MessageSignerStorage {
        address value;
    }

    /// @notice Struct which contains owner address of IPOR Protocol Router.
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains appointed owner address of IPOR Protocol Router.
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Struct which contains reentrancy status of IPOR Protocol Router.
    struct ReentrancyStatusStorage {
        uint256 value;
    }

    /// @notice Struct which contains information about swap liquidators.
    /// @dev First key is an asset (pool), second key is an liquidator address in the asset pool,
    /// value is a flag to indicate whether account is a liquidator.
    /// True - account is a liquidator, False - account is not a liquidator.
    struct AmmSwapsLiquidatorsStorage {
        mapping(address asset => mapping(address account => bool isLiquidator)) value;
    }

    /// @notice Struct which contains information about accounts appointed to rebalance.
    /// @dev first key - asset address, second key - account address which is allowed to rebalance in the asset pool,
    /// value - flag to indicate whether account is allowed to rebalance. True - allowed, False - not allowed.
    struct AmmPoolsAppointedToRebalanceStorage {
        mapping(address asset => mapping(address account => bool isAppointedToRebalance)) value;
    }

    struct AmmPoolsParamsValue {
        /// @dev max liquidity pool balance in the asset pool, represented without 18 decimals
        uint32 maxLiquidityPoolBalance;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        uint32 autoRebalanceThreshold;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        uint16 ammTreasuryAndAssetManagementRatio;
    }

    /// @dev key - asset address, value - struct AmmOpenSwapParamsValue
    struct AmmPoolsParamsStorage {
        mapping(address asset => AmmPoolsParamsValue) value;
    }

    /// @dev key - function sig, value - 1 if function is paused, 0 if not
    struct RouterFunctionPausedStorage {
        mapping(bytes4 sig => uint256 isPaused) value;
    }

    /// @notice Gets Ipor Protocol Router owner address.
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router appointed owner address.
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router reentrancy status.
    function getReentrancyStatus() internal pure returns (ReentrancyStatusStorage storage reentrancyStatus) {
        uint256 slot = _getStorageSlot(StorageId.ReentrancyStatus);
        assembly {
            reentrancyStatus.slot := slot
        }
    }

    /// @notice Gets information if function is paused in Ipor Protocol Router.
    function getRouterFunctionPaused() internal pure returns (RouterFunctionPausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.RouterFunctionPaused);
        assembly {
            paused.slot := slot
        }
    }

    /// @notice Gets point to pause guardian storage.
    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to liquidators storage.
    /// @return store - point to liquidators storage.
    function getAmmSwapsLiquidatorsStorage() internal pure returns (AmmSwapsLiquidatorsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapsLiquidators);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to accounts appointed to rebalance storage.
    /// @return store - point to accounts appointed to rebalance storage.
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

    /// @notice Gets point to amm pools params storage.
    /// @return store - point to amm pools params storage.
    function getAmmPoolsParamsStorage() internal pure returns (AmmPoolsParamsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsParams);
        assembly {
            store.slot := slot
        }
    }

    function getMessageSignerStorage() internal pure returns (MessageSignerStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.MessageSigner);
        assembly {
            store.slot := slot
        }
    }

    function getAssetLensDataStorage() internal pure returns (AssetLensDataStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AssetLensData);
        assembly {
            store.slot := slot
        }
    }

    function getAssetGovernancePoolConfigStorage()
        internal
        pure
        returns (AssetGovernancePoolConfigStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AssetGovernancePoolConfig);
        assembly {
            store.slot := slot
        }
    }

    function getAssetServicesStorage() internal pure returns (AssetServicesStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AssetServices);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}
