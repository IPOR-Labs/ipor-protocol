// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "contracts/libraries/StorageLib.sol";

/// @title Interface for interacting with AmmGovernanceLens. Interface responsible for reading data from AMM Governance.
interface IAmmGovernanceLens {
    /// @notice Structure of common params described AMM Pool configuration
    struct AmmGovernancePoolConfiguration {
        /// @notice address of asset which represents specific pool
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice address of AMM Storage
        address ammStorage;
        /// @notice address of AMM Treasury
        address ammTreasury;
        /// @notice address of AMM Pools Treasury Wallet
        address ammPoolsTreasury;
        /// @notice address of user which is allowed to manage AMM Pools Treasury Wallet
        address ammPoolsTreasuryManager;
        /// @notice address of AMM Charlie Treasury Wallet
        address ammCharlieTreasury;
        /// @notice address of user which is allowed to manage AMM Charlie Treasury Wallet
        address ammCharlieTreasuryManager;
    }

    /// @dev A struct to represent a pool's parameters configuration.
    struct AmmPoolsParamsConfiguration {
        /// @dev max liquidity pool balance in the asset pool, represented in 18 decimals
        uint256 maxLiquidityPoolBalance;
        /// @dev  max lp account contribution in the asset pool, represented in 18 decimals
        uint256 maxLpAccountContribution;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        /// Value represents multiplication of 1000.
        uint256 autoRebalanceThresholdInThousands;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        uint256 ammTreasuryAndAssetManagementRatio;
    }

    /// @notice Gets the structure or common params described AMM Pool configuration
    /// @param asset Address of asset which represents specific pool
    /// @return poolConfiguration Structure of common params described AMM Pool configuration
    function getAmmGovernancePoolConfiguration(
        address asset
    ) external view returns (AmmGovernancePoolConfiguration memory);

    /// @notice Flag which indicates if given account is an liquidator for given asset
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is checked if is an liquidator
    /// @return isSwapLiquidator Flag which indicates if given account is an liquidator for given asset
    function isSwapLiquidator(address asset, address account) external view returns (bool);

    /// @notice Flag which indicates if given account is an appointed to rebalance in AMM for given asset
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is checked if is an appointed to rebalance in AMM
    /// @return isAppointedToRebalanceInAmm Flag which indicates if given account is an appointed to rebalance in AMM for given asset
    function isAppointedToRebalanceInAmm(address asset, address account) external view returns (bool);

    /// @notice Gets the structure or common params described AMM Pool configuration
    /// @param asset Address of asset which represents specific pool
    /// @return ammPoolsParams Structure of common params described AMM Pool configuration
    function getAmmPoolsParams(address asset) external view returns (AmmPoolsParamsConfiguration memory);
}
