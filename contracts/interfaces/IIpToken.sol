// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of ipToken - Liquidity Pool Token managed by Joseph in IPOR Protocol for a given asset.
/// For more information refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidity-provisioning#liquidity-tokens
interface IIpToken is IERC20 {
    /// @notice Gets the asset / stablecoin address which is assocciated with particular ipToken smart contract instance
    /// @return asset / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Sets Joseph's address. Owner only
    /// @dev only Joseph can mint or burn ipTokens. Function emits `JosephChanged` event.
    /// @param newJoseph Joseph's address
    function setJoseph(address newJoseph) external;

    /// @notice Creates the ipTokens in the `amount` given and assigns them to the `account`
    /// @dev Emits {Transfer} from ERC20 asset and {Mint} event from ipToken
    /// @param account to which the created ipTokens were assigned
    /// @param amount volume of ipTokens created
    function mint(address account, uint256 amount) external;

    /// @notice Burns the `amount` of ipTokens from `account`, reducing the total supply
    /// @dev Emits {Transfer} from ERC20 asset and {Burn} event from ipToken
    /// @param account from which burned ipTokens are taken
    /// @param amount volume of ipTokens that will be burned, represented in 18 decimals
    function burn(address account, uint256 amount) external;

    /// @notice Emmited after the `amount` ipTokens were mint and transferred to `account`.
    /// @param account address where ipTokens are transferred after minting
    /// @param amount of ipTokens minted, represented in 18 decimals
    event Mint(address indexed account, uint256 amount);

    /// @notice Emmited after `amount` ipTokens were transferred from `account` and burnt.
    /// @param account address from which ipTokens are transferred to be burned
    /// @param amount volume of ipTokens burned
    event Burn(address indexed account, uint256 amount);

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
