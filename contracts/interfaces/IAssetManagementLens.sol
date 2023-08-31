// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

/// @title AssetManagementLens interface responsible for reading data from AssetManagement.
interface IAssetManagementLens {
    /// @dev A struct to represent an asset configuration.
    struct AssetManagementConfiguration {
        /// @notice The address of the asset.
        address asset;
        /// @notice Asset decimals.
        uint256 decimals;
        /// @notice The address of the asset management contract.
        address assetManagement;
        /// @notice The address of the AMM treasury contract.
        address ammTreasury;
    }

    /// @notice Gets the AssetManagement configuration for the given asset.
    /// @param asset The address of the asset.
    /// @return AssetManagementConfiguration The AssetManagement configuration for the given asset.
    function getAssetManagementConfiguration(address asset) external view returns (AssetManagementConfiguration memory);

    /// @notice Gets balance of the AmmTreasury contract in the AssetManagement.
    /// @dev This includes assets transferred to AssetManagement.
    /// @param asset The address of the asset.
    /// @return uint256 The total balance for the specified account, represented in 18 decimals.
    function balanceOfAmmTreasuryInAssetManagement(address asset) external view returns (uint256);

    /// @notice Get the balance of AAVE strategy in Asset Management module for the given asset.
    /// @param asset The address of the asset.
    /// @return uint256 The balance of the account in the AAVE protocol.
    function balanceOfStrategyAave(address asset) external view returns (uint256);

    /// @notice Get the balance of Compound strategy in Asset Management module for the given asset.
    /// @param asset The address of the asset.
    /// @return uint256 The balance of the account in the Compound protocol.
    function balanceOfStrategyCompound(address asset) external view returns (uint256);

    /// @notice Calculated exchange rate between ivToken and the underlying asset. Asset is specific to AssetManagement's intance (ex. USDC, USDT, DAI, etc.)
    /// @param asset The address of the asset.
    /// @return Current exchange rate between ivToken and the underlying asset, represented in 18 decimals.
    function getIvTokenExchangeRate(address asset) external view returns (uint256);
}
