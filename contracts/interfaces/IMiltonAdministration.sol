// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton, smart contract resposnible for working Automated Market Maker, administration part.
interface IMiltonAdministration {
    /// @notice Closes Pay Fixed Swap for given id in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Pay Fixed Swap Id.
    function emergencyCloseSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive Fixed Swap for given id in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Receive Fixed Swap Id.
    function emergencyCloseSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay Fixed Swaps for given list of ids in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive Fixed Swaps for given list of ids in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Receive Fixed swaps.
    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Milton.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Milton.
    function unpause() external;

    /// @notice sets max allowance for a given spender. Action available only for Owner.
    /// @param spender account which will have rights to spend ERC20 underlying assets on behalf of Milton
    function setupMaxAllowanceForAsset(address spender) external;

    /// @notice Sets Joseph address. Function available only for Owner.
    /// @param newJoseph new Joseph address
    function setJoseph(address newJoseph) external;

    /// @notice Emmited when Joseph address is changed by its owner.
    /// @param changedBy account address that changed Joseph's address
    /// @param oldJoseph old address of Joseph
    /// @param newJoseph new address of Joseph
    event JosephChanged(
        address indexed changedBy,
        address indexed oldJoseph,
        address indexed newJoseph
    );
}
