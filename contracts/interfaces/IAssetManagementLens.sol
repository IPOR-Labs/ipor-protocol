// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IAssetManagementLens {

    /// @dev A struct to represent an asset configuration.
    /// @param asset The address of the asset.
    /// @param decimals The number of decimal places the asset uses.
    /// @param assetManagement The address of the asset management contract.
    struct AssetManagementConfiguration {
        address asset;
        uint256 decimals;
        address assetManagement;
        address ammTreasury;
    }

    /// @notice Gets total balance of specific account for the given asset.
    /// @dev This includes assets transferred to AssetManagement.
    /// @param asset The address of the asset.
    /// @return uint256 The total balance for the specified account, represented in 18 decimals.
    function balanceOfAmmTreasury(address asset) external view returns (uint256);

    /// @notice Get the balance of a specific account in the Aave protocol for the given asset.
    /// @param asset The address of the asset.
    /// @return uint256 The balance of the account in the Aave protocol.
    function aaveBalanceOf(address asset) external view returns (uint256);

    /// @notice Get the balance of a specific account in the Compound protocol for the given asset.
    /// @param asset The address of the asset.
    /// @return uint256 The balance of the account in the Compound protocol.
    function compoundBalanceOf(address asset) external view returns (uint256);

    /// @notice Calculated exchange rate between ivToken and the underlying asset. Asset is specific to AssetManagement's intance (ex. USDC, USDT, DAI, etc.)
    /// @return Current exchange rate between ivToken and the underlying asset, represented in 18 decimals.
    function getIvTokenExchangeRate(address asset) external view returns (uint256);
}
