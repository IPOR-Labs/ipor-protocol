// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interaction with Stanley DSR smart contract.
/// @notice Stanley is responsible for delegating assets stored in Milton to Asset Management and forward to money market where they can earn interest.
interface IAssetManagementDsr {

    /// @notice Gets total balance of Milton (AmmTreasury), transferred assets to Stanley.
    /// @return Total balance for specific account given as a parameter, represented in 18 decimals.
    function totalBalance() external view returns (uint256);

    /// @notice Deposits ERC20 underlying assets to Stanley. Function available only for Milton.
    /// @dev Emits {Deposit} event from Stanley, emits {Mint} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount amount deposited by Milton to Stanley.
    /// @return vaultBalance current balance including amount deposited on Stanley.
    /// @return depositedAmount final deposited amount.
    function deposit(uint256 amount) external returns (uint256 vaultBalance, uint256 depositedAmount);

    /// @notice Withdraws declared amount of asset from Stanley to Milton. Function available only for Milton.
    /// @dev Emits {Withdraw} event from Stanley, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount deposited amount of underlying asset
    /// @return withdrawnAmount final withdrawn amount of asset from Stanley, can be different than input amount due to passing time.
    /// @return vaultBalance current asset balance on Stanley
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Withdraws all of the asset from Stanley to Milton. Function available only for Milton.
    /// @dev Emits {Withdraw} event from Stanley, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Output values are represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of the asset.
    /// @return vaultBalance current asset's balance on Stanley
    function withdrawAll() external returns (uint256 withdrawnAmount, uint256 vaultBalance);


    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from Stanley.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Stanley.
    function unpause() external;

    /// @notice Checks if given account is a pause guardian.
    /// @param account The address of the account to be checked.
    /// @return true if account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param guardian The address of the pause guardian to be added.
    function addPauseGuardian(address guardian) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param guardian The address of the pause guardian to be removed.
    function removePauseGuardian(address guardian) external;

    /// @notice Emitted after Milton has executed deposit function.
    /// @param timestamp moment when deposit function was executed
    /// @param from account address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param amount of asset transferred from Milton to Stanley, represented in 18 decimals
    event Deposit(uint256 timestamp, address from, address to, uint256 amount);

    /// @notice Emitted when Milton executes withdraw function.
    /// @param timestamp moment when deposit was executed
    /// @param to account address where assets are transferred to
    /// @param amount of asset transferred from Milton to Stanley, represented in 18 decimals
    event Withdraw(uint256 timestamp, address to, uint256 amount);
}
