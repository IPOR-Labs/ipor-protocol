// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author psirex
/// @notice Extends the ERC20 functionality that allows the bridge to mint/burn tokens
interface IERC20Bridged is IERC20 {
    /// @notice Returns bridge which can mint and burn tokens on L2
    function bridge() external view returns (address);

    /// @notice Creates amount_ tokens and assigns them to account_, increasing the total supply
    /// @param account_ An address of the account to mint tokens
    /// @param amount_ An amount of tokens to mint
    function bridgeMint(address account_, uint256 amount_) external;

    /// @notice Destroys amount_ tokens from account_, reducing the total supply
    /// @param account_ An address of the account to burn tokens
    /// @param amount_ An amount of tokens to burn
    function bridgeBurn(address account_, uint256 amount_) external;
}