// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of IpToken, which is Liquidity Pool Token managed by Joseph in IPOR Protocol for a given asset.
interface IIpToken is IERC20 {
    /// @notice Gets asset / stablecoin address which is assocciated with this IpToken smart contract instance
    /// @return asset / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Sets Joseph address by Owner
    /// @dev only Joseph can mind or burn IP Tokens. Emits `JosephChanged` event.
    /// @param newJoseph Joseph address
    function setJoseph(address newJoseph) external;

    /// @notice Creates `amount` IP Tokens and assign them to `account`
    /// @dev Emits {Transfer} and {Mint} events
    /// @param account to which the created IP Tokens were assigned
    /// @param amount volume of IP Tokens which will be created
    function mint(address account, uint256 amount) external;

    /// @notice Destroys `amount` IP Tokens from `account`, reducing the total supply
    /// @dev Emits {Transfer} and {Burn} events
    /// @param account from which the destroyed IP Tokens will be taken
    /// @param amount volume of IP Tokens which will be destroyed
    function burn(address account, uint256 amount) external;

    /// @notice Emmited when `amount` IP Tokens were mint and transfered to `account`.
    /// @param account address where IP Tokens are transfered after mind
    /// @param amount volume of IP Tokens which will be minted
    event Mint(address indexed account, uint256 amount);

    /// @notice Emmited when `amount` IP Tokens were burnt and transfered from `account`.
    /// @param account address where IP Tokens are transfered from, after burn
    /// @param amount volume of IP Tokens which will be burned
    event Burn(address indexed account, uint256 amount);

    /// @notice Emmited when Joseph address is changed by Owner.
    /// @param changedBy account address who changed Joseph address
    /// @param newJosephAddress new Joseph address
    event JosephChanged(address changedBy, address newJosephAddress);
	
}
