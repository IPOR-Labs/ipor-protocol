// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/AmmTypes.sol";

/// @title Interface for interaction with AmmTreasury, smart contract responsible for storing assets treasury for AMM
interface IAmmTreasury {
    /// @notice Gets configuration of AmmTreasury
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

    /// @notice Returns current version of AmmTreasury
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return Current AmmTreasury's version
    function getVersion() external pure returns (uint256);

    /// @notice Transfers the assets from AmmTreasury to AssetManagement.
    /// @dev AmmTreasury balance in storage is not changing after this deposit, balance of ERC20 assets on AmmTreasury
    /// is changing as they get transferred to AssetManagement.
    /// @dev Emits {Deposit} event from AssetManagement, emits {Transfer} event from ERC20, emits {Mint} event from ivToken
    /// @param assetAmount amount of asset
    /// @dev Function can be executed only by IPOR Protocol Router as internal interaction.
    function depositToAssetManagementInternal(uint256 assetAmount) external;

    /// @notice Transfers the assets from AssetManagement to AmmTreasury.
    /// @dev AmmTreasury balance in storage is not changing, balance of ERC20 assets of AmmTreasury is changing.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @param assetAmount amount of assets
    /// @dev Function can be executed only by IPOR Protocol Router as internal interaction.
    function withdrawFromAssetManagementInternal(uint256 assetAmount) external;

    /// @notice Transfers assets (underlying tokens / stable coins) from AssetManagement to AmmTreasury.
    /// @dev AmmTreasury Balance in storage is not changing after this withdraw, balance of ERC20 assets on AmmTreasury is changing.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @dev Function can be executed only by IPOR Protocol Router as internal interaction.
    function withdrawAllFromAssetManagementInternal() external;

    /// @notice Pauses current smart contract, it can be executed only by the AmmTreasury contract Owner
    /// @dev Emits {Paused} event from AmmTreasury.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the AmmTreasury contract Owner
    /// @dev Emits {Unpaused} event from AmmTreasury.
    function unpause() external;

    /// @notice sets max allowance for a given spender. Action available only for AmmTreasury contract Owner.
    /// @param spender account which will have rights to transfer ERC20 underlying assets on behalf of AmmTreasury
    function setupMaxAllowanceForAsset(address spender) external;
}
