// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/AmmTypes.sol";

/// @title Interface for interaction with AmmTreasury, smart contract resposnible for issuing and closing interest rate swaps also known as Automated Market Maker - administrative part.
interface IAmmTreasury {
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

    /// @notice Transfers the assets from AmmTreasury to AssetManagement. Action available only to Router.
    /// @dev AmmTreasury balance in storage is not changing after this deposit, balance of ERC20 assets on AmmTreasury is changing as they get transfered to AssetManagement.
    /// @dev Emits {Deposit} event from AssetManagement, emits {Transfer} event from ERC20, emits {Mint} event from ivToken
    /// @param assetAmount amount of asset
    function depositToAssetManagement(uint256 assetAmount) external;

    /// @notice Transfers the assets from AssetManagement to AmmTreasury. Action available only for Router.
    /// @dev AmmTreasury balance in storage is not changing, balance of ERC20 assets of AmmTreasury is changing.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @param assetAmount amount of assets
    function withdrawFromAssetManagement(uint256 assetAmount) external;

    /// @notice Transfers assets (underlying tokens / stablecoins) from AssetManagement to AmmTreasury. Action available only for Router.
    /// @dev AmmTreasury Balance in storage is not changing after this wi, balance of ERC20 assets on AmmTreasury is changing.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    function withdrawAllFromAssetManagement() external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from AmmTreasury.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AmmTreasury.
    function unpause() external;

    /// @notice sets max allowance for a given spender. Action available only for Owner.
    /// @param spender account which will have rights to transfer ERC20 underlying assets on behalf of AmmTreasury
    function setupMaxAllowanceForAsset(address spender) external;
}
