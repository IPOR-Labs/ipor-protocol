// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Interface for interaction with  Stanley's strategy.
/// @notice Strategy represents an external DeFi protocol and acts as and wrapper that standarizes the API of the external protocol.
interface IStrategyDsr {
    /// @notice Returns current version of strategy
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current Strategy's version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Strategy instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Returns strategy's share token address
    function getShareToken() external view returns (address);

    /// @notice Gets annualised interest rate (APR) for this strategy.
    /// @return APR value, represented in 18 decimals.
    function getApr() external view returns (uint256);

    /// @notice Gets balance for given asset (underlying / stablecoin) allocated to this strategy.
    /// @return balance for given asset, represented in 18 decimals.
    function balanceOf() external returns (uint256);

    /// @notice Deposits asset amount from Stanley to this specific Strategy. Function available only for Stanley.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    function deposit(uint256 amount) external returns (uint256 depositedAmount);

    /// @notice Withdraws asset amount from Strategy to Stanley. Function available only for Stanley.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    /// @return withdrawnAmount The final amount withdrawn, represented in 18 decimals
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount);

    /// @notice Gets Stanley address.
    function getStanley() external view returns (address);

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Strategy implementation.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Strategy implementation.
    function unpause() external;
}
