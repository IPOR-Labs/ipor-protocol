// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of IvToken, which is IPOR Vault Token managed by Stanley in IPOR Protocol for a given asset.
interface IIvToken is IERC20 {
    /// @notice Gets asset / stablecoin address which is assocciated with this IvToken smart contract instance
    /// @return asset / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Sets Stanley address by Owner
    /// @dev only Stanley can mind or burn IV Tokens. Emits `StanleyChanged` event.
    /// @param newStanley Stanley address
    function setStanley(address newStanley) external;

    /// @notice Creates `amount` IV Tokens and assign them to `account`
    /// @dev Emits {Transfer} and {Mint} events
    /// @param account to which the created IV Tokens were assigned
    /// @param amount volume of IV Tokens which will be created
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    event Mint(address indexed account, uint256 amount);

    event Burn(address indexed account, uint256 amount);

    event StanleyChanged(address changedBy, address newStanleyAddress);
}
