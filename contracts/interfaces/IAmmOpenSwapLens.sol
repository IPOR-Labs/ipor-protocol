// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapLens {
    /// @notice Structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    struct AmmOpenSwapServicePoolConfiguration {
        /// @notice address of the asset
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice address of the AMM Storage
        address ammStorage;
        /// @notice address of the AMM Treasury
        address ammTreasury;
        /// @notice ipor publication fee, fee used when opening swap, represented in 18 decimals.
        uint256 iporPublicationFee;
        /// @notice maximum swap collateral amount, represented in 18 decimals.
        uint256 maxSwapCollateralAmount;
        /// @notice liquidation deposit amount, represented WITHOUT 18 decimals. Example 25 = 25 USDT.
        uint256 liquidationDepositAmount;
        /// @notice minimum leverage, represented in 18 decimals.
        uint256 minLeverage;
        /// @notice swap's opening fee rate, represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeRate;
        /// @notice swap's opening fee rate, portion of the rate which is allocated to "treasury" balance
        /// @dev Value describes what percentage of opening fee amount is allocated to "treasury" balance. Value represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeTreasuryPortionRate;
    }

    /// @notice Returns configuration of the AmmOpenSwapServicePool for specific asset (pool).
    /// @param asset address of the asset
    /// @return AmmOpenSwapServicePoolConfiguration structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    function getAmmOpenSwapServicePoolConfiguration(
        address asset
    ) external view returns (AmmOpenSwapServicePoolConfiguration memory);
}
