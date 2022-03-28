// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with specific Stanley's strategy which represent external DeFi protocol.
interface IStrategy {
    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Strategy instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets share token address
    /// return strategy's share token address
    function getShareToken() external view returns (address);

    /// @notice Gets Annyal Percentage Rate for this strategy.
    /// @return APR value, represented in 18 decimals.
    function getApr() external view returns (uint256);

    /// @notice Gets balance for given asset (underlying / stablecoin) in this strategy.
    /// @return balance for given asset, represented in 18 decimals.
    function balanceOf() external view returns (uint256);

    /// @notice Deposits given asset amount from Stanley to this specific Strategy. Function available only for Stanley.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    function deposit(uint256 amount) external;

    /// @notice Withdraws given asset amount from Strategy to Stanley. Function available only for Stanley.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    function withdraw(uint256 amount) external;

    /// @notice Extra steps executed before claim rewards. Function can be executed by anyone.
    function beforeClaim() external;

    /// @notice Claim rewards. Function can be executed by anyone.
    function doClaim() external;

    /// @notice Sets new Stanley address. Function can be executed only by smart contract Owner.
    /// @param newStanley new Stanley address
    function setStanley(address newStanley) external;

    /// @notice Sets new Treasury address. Function can be executed only by smart contract Owner.
    /// @param newTreasury new Treasury address
    function setTreasury(address newTreasury) external;

    /// @notice Sets new Treasury Manager address. Function can be executed only by smart contract Owner.
    /// @param newTreasuryManager new Treasury Manager address
    function setTreasuryManager(address newTreasuryManager) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Strategy implementation.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Strategy implementation.
    function unpause() external;

    /// @notice Emmited when Stanley address is changed by Owner.
    /// @param changedBy account address who changed Stanley address
    /// @param oldStanley old Stanley address
    /// @param newStanley new Stanley address
    event StanleyChanged(address changedBy, address oldStanley, address newStanley);

    // TODO: ADD test for events into fork test
    /// @notice Emmited when doClaim function was executed.
    /// @param strategy strategy address where claim was executed.
    /// @param shareTokens
    event DoClaim(
        address indexed strategy,
        address[] shareTokens,
        address claimAddress,
        uint256 amount
    );

    /// @notice Emmited when beforeClaim function was executed.
    //TODO: check emition
    event DoBeforeClaim(address strategy, address[] assets);

    /// @notice Emmited when Treasury address changed
    /// @param changedBy account address who changed Treasury address
    /// @param oldTreasury old Treasury address
    /// @param newTreasury new Treasury address
    //TODO: check emition
    event TreasuryChanged(address changedBy, address oldTreasury, address newTreasury);

    /// @notice Emmited when Treasury Manager address changed
    /// @param changedBy account address who changed Treasury Manager address
    /// @param oldTreasuryManager old Treasury Manager address
    /// @param newTreasuryManager new Treasury Manager address
    //TODO: check emition
    event TreasuryManagerChanged(
        address changedBy,
        address oldTreasuryManager,
        address newTreasuryManager
    );

    /// @notice Emmited when Stk AAVE address changed
    /// @param changedBy account address who changed Stk AAVE address
    /// @param oldStkAave old Stk Aave address
    /// @param newStkAave new Stk Aave address
    //TODO: check emition
    event StkAaveChanged(address changedBy, address oldStkAave, address newStkAave);
}
