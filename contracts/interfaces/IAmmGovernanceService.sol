// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interacting with the AmmGovernanceService. Interface responsible for managing AMM Pools.
interface IAmmGovernanceService {
    /// @notice Transfers the asset amount from the AmmTreasury to the AssetManagement. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function depositToAssetManagement(address asset, uint256 assetAmount) external;

    /// @notice Transfers the asset amount from the AssetManagement to the AmmTreasury. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function withdrawFromAssetManagement(address asset, uint256 assetAmount) external;

    /// @notice Transfers all of the asset from the AssetManagement to the AmmTreasury. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of the asset representing specific pool
    function withdrawAllFromAssetManagement(address asset) external;

    /// @notice Transfers the asset amount from the AmmTreasury to the Treasury Wallet. Action available only to the AMM Treasury Manager.
    /// @dev The AMM collects a part of swap's opening fee adn accounts it towards the "treasury".
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function transferToTreasury(address asset, uint256 assetAmount) external;

    /// @notice Transfers the asset amount from the AmmTreasury to Oracle Treasury Wallet. Action available only to the  AMM Charlie Treasury Manager.
    /// @dev A specific balance known as "iporPublicationFee" exists in AmmTreasury, which is used to collect IPOR publication fees from traders when they initiate swaps.
    /// @dev Within the AmmTreasury, there exists a distinct balance known as "iporPublicationFee," which is utilized by the AMM to accumulate IPOR publication fees from traders as they open swaps.
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function transferToCharlieTreasury(address asset, uint256 assetAmount) external;

    /// @notice Adds an account to the list of swap liquidators for a given asset. Action available only to IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param account Address of an account added to the list of swap liquidators
    function addSwapLiquidator(address asset, address account) external;

    /// @notice Removes an account from the list of swap liquidators for a given asset. Action available only to IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param account Address of an account removed to the list of swap liquidators
    function removeSwapLiquidator(address asset, address account) external;

    /// @notice Add an account to the list of addresses appointed to rebalance AMM for given asset. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param account Address of an account added to the list of addresses appointed to rebalance in AMM
    /// @dev Rebalancing the AMM is a process of moving liquidity between the AMM and the AssetManagement in the amount defined in param called "ammTreasuryAndAssetManagementRatio".
    function addAppointedToRebalanceInAmm(address asset, address account) external;

    /// @notice Remove account from the list of appointed to rebalance in AMM for given asset.
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is removed from the list of appointed to rebalance in AMM
    /// @dev Rebalancing the AMM is a process of moving liquidity between the AMM and the AssetManagement in the amount defined in param called "ammTreasuryAndAssetManagementRatio".
    function removeAppointedToRebalanceInAmm(address asset, address account) external;

    /// @notice Sets AMM Pools params for a given asset (pool). Action available only to IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
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
