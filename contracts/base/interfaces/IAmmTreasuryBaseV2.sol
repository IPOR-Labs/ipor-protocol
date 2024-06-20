// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IAmmTreasuryBaseV1} from "./IAmmTreasuryBaseV1.sol";

/// @notice Interface of the AmmTreasury contract which supports Asset Management / Plasma Vault.
interface IAmmTreasuryBaseV2 is IAmmTreasuryBaseV1 {
    /// @notice Transfers the assets from the AmmTreasury to the Asset Management.
    /// @dev AmmTreasury balance in storage is not changing after this deposit, balance of ERC20 assets on AmmTreasury
    /// is changing as they get transferred to the AmmVault.
    /// @param wadAssetAmount amount of asset, value represented in 18 decimals
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function depositToAssetManagementInternal(uint256 wadAssetAmount) external;

    /// @notice Transfers the assets from the Asset Management to the AmmTreasury.
    /// @dev AmmTreasury balance in storage is not changing, balance of ERC20 assets of AmmTreasury is changing.
    /// @param wadAssetAmount amount of assets, value represented in 18 decimals
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function withdrawFromAssetManagementInternal(uint256 wadAssetAmount) external;

    /// @notice Transfers assets (underlying tokens) from the Asset Management to the AmmTreasury.
    /// @dev AmmTreasury Balance in storage is not changing after this withdraw, balance of ERC20 assets on AmmTreasury is changing.
    /// @dev Function can be executed only by the IPOR Protocol Router as internal interaction.
    function withdrawAllFromAssetManagementInternal() external;

}
