// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interaction with AssetManagement smart contract.
/// @notice AssetManagement is responsible for delegating assets stored in AmmTreasury to money markets where they can earn interest.
interface IAssetManagement {
    /// @notice Gets total balance of account `who`,  transferred assets to AssetManagement.
    /// @param who Account for which total balance is returned.
    /// @return Total balance for specific account given as a parameter, represented in 18 decimals.
    function totalBalance(address who) external view returns (uint256);

    /// @notice Calculated exchange rate between ivToken and the underlying asset. Asset is specific to AssetManagement's intance (ex. USDC, USDT, DAI, etc.)
    /// @return Current exchange rate between ivToken and the underlying asset, represented in 18 decimals.
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Deposits ERC20 underlying assets to AssetManagement. Function available only for AmmTreasury.
    /// @dev Emits {Deposit} event from AssetManagement, emits {Mint} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount amount deposited by AmmTreasury to AssetManagement.
    /// @return vaultBalance current balance including amount deposited on AssetManagement.
    /// @return depositedAmount final deposited amount.
    function deposit(uint256 amount) external returns (uint256 vaultBalance, uint256 depositedAmount);

    /// @notice Withdraws declared amount of asset from AssetManagement to AmmTreasury. Function available only for AmmTreasury.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount deposited amount of underlying asset
    /// @return withdrawnAmount final withdrawn amount of asset from AssetManagement, can be different than input amount due to passing time.
    /// @return vaultBalance current asset balance on AssetManagement
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Withdraws all of the asset from AssetManagement to AmmTreasury. Function available only for AmmTreasury.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Output values are represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of the asset.
    /// @return vaultBalance current asset's balance on AssetManagement
    function withdrawAll() external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Emitted after AmmTreasury has executed deposit function.
    /// @param timestamp moment when deposit function was executed
    /// @param from account address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param exchangeRate exchange rate of ivToken, represented in 18 decimals
    /// @param amount of asset transferred from AmmTreasury to AssetManagement, represented in 18 decimals
    /// @param ivTokenAmount amount calculated based on `exchangeRate` and `amount`, represented in 18 decimals.
    event Deposit(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenAmount
    );

    /// @notice Emitted when AmmTreasury executes withdraw function.
    /// @param timestamp moment when deposit was executed
    /// @param from account address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param exchangeRate exchange rate of ivToken, represented in 18 decimals
    /// @param amount of asset transferred from AmmTreasury to AssetManagement, represented in 18 decimals
    /// @param ivTokenAmount amount of ivToken calculated based on `exchangeRate` and `amount`, represented in 18 decimals.
    event Withdraw(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenAmount
    );
}
