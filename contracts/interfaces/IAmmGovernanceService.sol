// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "../libraries/StorageLib.sol";

/// @title Interface for interacting with AmmGovernanceService. Interface responsible for managing AMM Pools.
interface IAmmGovernanceService {
    /// @notice Transfers the asset amount from AmmTreasury to AssetManagement. Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    /// @param assetAmount Amount of asset to transfer
    function depositToAssetManagement(address asset, uint256 assetAmount) external;

    /// @notice Transfers the asset amount from AssetManagement to AmmTreasury. Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    /// @param assetAmount Amount of asset to transfer
    function withdrawFromAssetManagement(address asset, uint256 assetAmount) external;

    /// @notice Transfers all asset amount from AssetManagement to AmmTreasury. Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    function withdrawAllFromAssetManagement(address asset) external;

    /// @notice Transfers the asset amount from AmmTreasury to Treasury Wallet. Action available only for AMM Treasury Manager.
    /// @dev In AmmTreasury is a dedicated balance called "treasury" where AMM collect part of swap's opening fee.
    /// @param asset Address of asset which represents specific pool
    /// @param assetAmount Amount of asset to transfer
    function transferToTreasury(address asset, uint256 assetAmount) external;

    /// @notice Transfers the asset amount from AmmTreasury to Charlie Treasury Wallet. Action available only for AMM Charlie Treasury Manager.
    /// @dev In AmmTreasury is a dedicated balance called "iporPublicationFee" where AMM collect IPOR publication fee when traders open swaps.
    /// @param asset Address of asset which represents specific pool
    /// @param assetAmount Amount of asset to transfer
    function transferToCharlieTreasury(address asset, uint256 assetAmount) external;

    /// @notice Add account to the list of swap liquidators for given asset. Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is added to the list of swap liquidators
    function addSwapLiquidator(address asset, address account) external;

    /// @notice Remove account from the list of swap liquidators for given asset. Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is removed from the list of swap liquidators
    function removeSwapLiquidator(address asset, address account) external;

    /// @notice Add account to the list of appointed to rebalance in AMM for given asset. Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is added to the list of appointed to rebalance in AMM
    /// @dev Rebalance in AMM is a process of moving liquidity from AMM to AssetManagement in a portion defined in param called "ammTreasuryAndAssetManagementRatio".
    function addAppointedToRebalanceInAmm(address asset, address account) external;

    /// @notice Remove account from the list of appointed to rebalance in AMM for given asset.
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is removed from the list of appointed to rebalance in AMM
    /// @dev Rebalance in AMM is a process of moving liquidity from AMM to AssetManagement in a portion defined in param called "ammTreasuryAndAssetManagementRatio".
    function removeAppointedToRebalanceInAmm(address asset, address account) external;

    /// @notice Sets AMM Pools params for given asset (pool). Action available only for IPOR Protocol Owner.
    /// @param asset Address of asset which represents specific pool
    /// @param newMaxLiquidityPoolBalance New max liquidity pool balance threshold. Value represented WITHOUT 18 decimals.
    /// @param newMaxLpAccountContribution New max liquidity pool account contribution threshold. Value represented WITHOUT 18 decimals.
    /// @param newAutoRebalanceThresholdInThousands New auto rebalance threshold in thousands. Value represented WITHOUT 18 decimals. Value represents multiplication of 1000.
    /// @param newAmmTreasuryAndAssetManagementRatio New AMM Treasury and Asset Management ratio, represented WITHOUT 18 decimals, value represents percentage with 2 decimals. Example: 65% = 6500, 99,99% = 9999
    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newMaxLpAccountContribution,
        uint32 newAutoRebalanceThresholdInThousands,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) external;
}
