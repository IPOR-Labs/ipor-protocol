// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//TODO: remove
/// @title Interface of IvToken, which is IPOR Vault Token managed by AssetManagement in IPOR Protocol for a given asset.
interface IIvToken is IERC20 {
    /// @notice Gets asset / stablecoin address which is associated with this IvToken smart contract instance
    /// @return asset / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Sets AssetManagement address by Owner
    /// @dev only AssetManagement can mind or burn IV Tokens. Emits {AssetManagementChanged} event.
    /// @param newAssetManagement AssetManagement address
    function setAssetManagement(address newAssetManagement) external;

    /// @notice Creates ivTokens in the given `amount`  and assigns them to the `account`
    /// @dev Emits {Transfer} from ERC20 asset and {Mint} event from ivToken
    /// @param account to which the created ivTokens are being assigned
    /// @param amount volume of ivTokens being created
    function mint(address account, uint256 amount) external;

    /// @notice Destroys ivTokens in the given `amount` assigned to the `account`, reducing the total supply
    /// @dev Emits {Transfer} event from ERC20 asset and {Burn} event from ivToken
    /// @param account from which the destroyed ivTokens are being taken
    /// @param amount volume of ivTokens being destroyed
    function burn(address account, uint256 amount) external;

    /// @notice Emitted when `amount` of ivTokens were minted and transferred to the`account`.
    /// @param account address where ivTokens are transferred after minting
    /// @param amount volume of ivTokens which will are being minted
    event Mint(address indexed account, uint256 amount);

    /// @notice Emitted when the `amount` of ivTokens from `account` was burnt.
    /// @param account address from where ivTokens are being burned
    /// @param amount of ivTokens being burned
    event Burn(address indexed account, uint256 amount);

    /// @notice Emitted when AssetManagement's address is changed by the owner.
    /// @param newAssetManagement AssetManagement's new address
    event AssetManagementChanged(address indexed newAssetManagement);
}
