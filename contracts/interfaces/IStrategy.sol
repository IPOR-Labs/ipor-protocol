// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Interface for interaction with  Stanley's strategy.
/// @notice Strategy represents an external DeFi protocol and acts as and wrapper that standarizes the API of the external protocol.
interface IStrategy {
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
    function balanceOf() external view returns (uint256);

    /// @notice Deposits asset amount from Stanley to this specific Strategy. Function available only for Stanley.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    function deposit(uint256 amount) external returns (uint256 depositedAmount);

    /// @notice Withdraws asset amount from Strategy to Stanley. Function available only for Stanley.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    /// @return withdrawnAmount The final amount withdrawn, represented in 18 decimals
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount);

    /// @notice Claims rewards. Function can be executed by anyone.
    function doClaim() external;

    /// @notice Gets Stanley address.
    function getStanley() external view returns (address);

    /// @notice Sets new Stanley address. Function can be executed only by the smart contract Owner.
    /// @param newStanley new Stanley address
    function setStanley(address newStanley) external;

    /// @notice Gets Treasury address.
    /// @return Treasury address.
    function getTreasury() external view returns (address);

    /// @notice Sets new Treasury address. Function can be executed only by the smart contract Owner.
    /// @param newTreasury new Treasury address
    function setTreasury(address newTreasury) external;

    /// @notice Gets new Treasury Manager address.
    /// @return Treasury Manager address.
    function getTreasuryManager() external view returns (address);

    /// @notice Sets new Treasury Manager address. Function can be executed only by the smart contract Owner.
    /// @param newTreasuryManager new Treasury Manager address
    function setTreasuryManager(address newTreasuryManager) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Strategy implementation.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Strategy implementation.
    function unpause() external;

    /// @notice Emmited when Stanley address is changed by Owner.
    /// @param changedBy account address that has changed Stanley address
    /// @param oldStanley old Stanley address
    /// @param newStanley new Stanley address
    event StanleyChanged(address changedBy, address oldStanley, address newStanley);

    /// @notice Emmited when doClaim function had been executed.
    /// @param claimedBy account that executes claim action
    /// @param shareToken share token assocciated with one strategy
    /// @param treasury Treasury address where claimed tokens are transferred.
    /// @param amount S
    event DoClaim(
        address indexed claimedBy,
        address indexed shareToken,
        address indexed treasury,
        uint256 amount
    );

    /// @notice Emmited when Treasury address has changed
    /// @param changedBy account address that has changed Treasury address
    /// @param oldTreasury old Treasury address
    /// @param newTreasury new Treasury address
    event TreasuryChanged(address changedBy, address oldTreasury, address newTreasury);

    /// @notice Emmited when Treasury Manager address has changed
    /// @param changedBy account address that changed Treasury Manager's address
    /// @param oldTreasuryManager old Treasury Manager address
    /// @param newTreasuryManager new Treasury Manager address
    event TreasuryManagerChanged(
        address changedBy,
        address oldTreasuryManager,
        address newTreasuryManager
    );
}
