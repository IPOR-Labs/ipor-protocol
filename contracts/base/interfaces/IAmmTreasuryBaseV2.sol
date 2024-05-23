// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @notice Interface of the AmmTreasury contract.
interface IAmmTreasuryBaseV2 {
    /// @notice Gets router address.
    function router() external view returns (address);

    /// @notice Retrieves the version number of the contract.
    /// @return The version number of the contract.
    /// @dev This function provides a way to access the version information of the contract.
    /// Currently, the version is set to 1.
    function getVersion() external pure returns (uint256);

    /// @notice Gets the balance of the liquidity pool.
    /// @dev Liquidity Pool balance not take into account following balances: collateral, ipor publication fee, treasury
    function getLiquidityPoolBalance() external view returns (uint256);

    /// @notice Transfers the assets from the AmmTreasury to the AmmVault.
    /// @dev AmmTreasury balance in storage is not changing after this deposit, balance of ERC20 assets on AmmTreasury
    /// is changing as they get transferred to the AmmVault.
    /// @param wadAssetAmount amount of asset, value represented in 18 decimals
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function depositToVaultInternal(uint256 wadAssetAmount) external;

    /// @notice Transfers the assets from the AmmVault to the AmmTreasury.
    /// @dev AmmTreasury balance in storage is not changing, balance of ERC20 assets of AmmTreasury is changing.
    /// @param wadAssetAmount amount of assets, value represented in 18 decimals
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function withdrawFromVaultInternal(uint256 wadAssetAmount) external;

    /// @notice Transfers assets (underlying tokens) from the AmmVault to the AmmTreasury.
    /// @dev AmmTreasury Balance in storage is not changing after this withdraw, balance of ERC20 assets on AmmTreasury is changing.
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function withdrawAllFromVaultInternal() external;

    /// @notice Pauses the contract and revokes the approval of stEth tokens for the router.
    /// @dev This function can only be called by the pause guardian.
    /// It revokes the approval of stEth tokens for the router and then pauses the contract.
    /// require Caller must be the pause guardian.
    function pause() external;

    /// @notice Unpauses the contract and forcefully approves the router to transfer an unlimited amount of stEth tokens.
    /// @dev This function can only be called by the contract owner.
    /// It unpauses the contract and then forcefully sets the approval of stEth tokens for the router to the maximum possible value.
    /// require Caller must be the contract owner.
    function unpause() external;

    /// @notice Checks if the given account is a pause guardian.
    /// @param account Address to be checked.
    /// @return A boolean indicating whether the provided account is a pause guardian.
    /// @dev This function queries the PauseManager to determine if the provided account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a new pause guardian to the contract.
    /// @param guardians List Addresses of the accounts to be added as a pause guardian.
    /// @dev This function can only be called by the contract owner.
    /// It delegates the addition of a new pause guardian to the PauseManager.
    /// require Caller must be the contract owner.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes an existing pause guardian from the contract.
    /// @param guardians List addresses of the accounts to be removed as a pause guardian.
    /// @dev This function can only be called by the contract owner.
    /// It delegates the removal of a pause guardian to the PauseManager.
    /// require Caller must be the contract owner.
    function removePauseGuardians(address[] calldata guardians) external;
}
