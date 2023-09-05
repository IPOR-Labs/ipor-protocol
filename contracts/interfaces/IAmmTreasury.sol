// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface for interaction with AmmTreasury, smart contract responsible for storing assets treasury for AMM
interface IAmmTreasury {
    /// @notice Returns the current version of AmmTreasury
    /// @dev Increase the number when the implementation inside source code is different that implementation deployed on Mainnet
    /// @return Current AmmTreasury's version
    function getVersion() external pure returns (uint256);

    /// @notice Gets the configuration of AmmTreasury
    /// @return asset address of asset
    /// @return decimals decimals of asset
    /// @return ammStorage address of AmmStorage
    /// @return assetManagement address of AssetManagement
    /// @return iporProtocolRouter address of IporProtocolRouter
    function getConfiguration()
        external
        view
        returns (
            address asset,
            uint256 decimals,
            address ammStorage,
            address assetManagement,
            address iporProtocolRouter
        );

    /// @notice Transfers the assets from the AmmTreasury to the AssetManagement.
    /// @dev AmmTreasury balance in storage is not changing after this deposit, balance of ERC20 assets on AmmTreasury
    /// is changing as they get transferred to the AssetManagement.
    /// @dev Emits {Deposit} event from AssetManagement, emits {Transfer} event from ERC20, emits {Mint} event from ivToken
    /// @param wadAssetAmount amount of asset, value represented in 18 decimals
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function depositToAssetManagementInternal(uint256 wadAssetAmount) external;

    /// @notice Transfers the assets from the AssetManagement to the AmmTreasury.
    /// @dev AmmTreasury balance in storage is not changing, balance of ERC20 assets of AmmTreasury is changing.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @param wadAssetAmount amount of assets, value represented in 18 decimals
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function withdrawFromAssetManagementInternal(uint256 wadAssetAmount) external;

    /// @notice Transfers assets (underlying tokens) from the AssetManagement to the AmmTreasury.
    /// @dev AmmTreasury Balance in storage is not changing after this withdraw, balance of ERC20 assets on AmmTreasury is changing.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function withdrawAllFromAssetManagementInternal() external;

    /// @notice sets the max allowance for a given spender. Action available only for AmmTreasury contract Owner.
    /// @param spender account which will have rights to transfer ERC20 underlying assets on behalf of AmmTreasury
    function grantMaxAllowanceForSpender(address spender) external;

    /// @notice sets the zero allowance for a given spender. Action available only for AmmTreasury contract Owner.
    /// @param spender account which will have rights to transfer ERC20 underlying assets on behalf of AmmTreasury
    function revokeAllowanceForSpender(address spender) external;

    /// @notice Pauses current smart contract, it can be executed only by the AmmTreasury contract Pause Guardian
    /// @dev Emits {Paused} event from AmmTreasury.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the AmmTreasury contract Owner
    /// @dev Emits {Unpaused} event from AmmTreasury.
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
}
