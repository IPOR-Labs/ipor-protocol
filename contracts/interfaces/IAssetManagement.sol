// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

/// @title Interface for interaction with Asset Management DSR smart contract.
/// @notice Asset Management is responsible for delegating assets stored in AmmTreasury to Asset Management and forward to money market where they can earn interest.
interface IAssetManagement {
    /// @notice Gets total balance of AmmTreasury, transferred assets to Asset Management.
    /// @return Total balance for specific account given as a parameter, represented in 18 decimals.
    function totalBalance() external view returns (uint256);

    /// @notice Deposits ERC20 underlying assets to AssetManagement. Function available only for AmmTreasury.
    /// @dev Emits {Deposit} event from AssetManagement, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount amount deposited by AmmTreasury to AssetManagement.
    /// @return vaultBalance current balance including amount deposited on AssteManagement.
    /// @return depositedAmount final deposited amount.
    function deposit(uint256 amount) external returns (uint256 vaultBalance, uint256 depositedAmount);

    /// @notice Withdraws declared amount of asset from AssetManagement to AmmTreasury. Function available only for AmmTreasury.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset.
    /// All input and output values are represented in 18 decimals.
    /// @param amount deposited amount of underlying asset represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of asset from AssetManagement, can be different than input amount due to passing time.
    /// @return vaultBalance current asset balance on AssetManagement
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Withdraws all of the asset from AssetManagement to AmmTreasury. Function available only for AmmTreasury.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset.
    /// Output values are represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of the asset.
    /// @return vaultBalance current asset's balance on AssetManagement
    function withdrawAll() external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Emitted after AmmTreasury has executed deposit function.
    /// @param from account address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param amount of asset transferred from AmmTreasury to AssetManagement, represented in 18 decimals
    event Deposit(address from, address to, uint256 amount);

}
