// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of IvToken, which is IPOR Vault Token managed by Stanley in IPOR Protocol for a given asset.
interface IIvToken is IERC20 {
    /// @notice Gets asset / stablecoin address which is assocciated with this IvToken smart contract instance
    /// @return asset / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Sets Stanley address by Owner
    /// @dev only Stanley can mind or burn IV Tokens. Emits {StanleyChanged} event.
    /// @param newStanley Stanley address
    function setStanley(address newStanley) external;

    /// @notice Creates `amount` IV Tokens and assign them to `account`
    /// @dev Emits {Transfer} from ERC20 asset and {Mint} event from ivToken
    /// @param account to which the created IV Tokens were assigned
    /// @param amount volume of IV Tokens which will be created
    function mint(address account, uint256 amount) external;

    /// @notice Destroys `amount` IV Tokens from `account`, reducing the total supply
    /// @dev Emits {Transfer} event from ERC20 asset and {Burn} event from ivToken
    /// @param account from which the destroyed IV Tokens will be taken
    /// @param amount volume of IV Tokens which will be destroyed
    function burn(address account, uint256 amount) external;

    /// @notice Emmited when `amount` IV Tokens were mint and transferred to `account`.
    /// @param account address where IV Tokens are transferred after mind
    /// @param amount volume of IV Tokens which will be minted
    event Mint(address indexed account, uint256 amount);

    /// @notice Emmited when `amount` IV Tokens were burnt and transferred from `account`.
    /// @param account address where IV Tokens are transferred from, after burn
    /// @param amount volume of IV Tokens which will be burned
    event Burn(address indexed account, uint256 amount);

    /// @notice Emmited when Stanley address is changed by Owner.
    /// @param changedBy account address who changed Stanley address
    /// @param oldStanley old Stanley address
    /// @param newStanley new Stanley address
    event StanleyChanged(
        address indexed changedBy,
        address indexed oldStanley,
        address indexed newStanley
    );
}
