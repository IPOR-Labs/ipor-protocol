// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Stanley smart contract - administration and maintenance part.
interface IStanleyAdministration {
    /// @notice Transfer all asset in current strategy to strategy with max APR. Function available only for Owner.
    /// @dev Emits {Deposit} or {Withdraw} event from Stanley depends on current asset balance on Milton and Stanley. Emits {Transfer} from ERC20 asset.
    function migrateAssetToStrategyWithMaxApr() external;

    /// @notice Sets AAVE stratedy address. Function available only for Owner.
    /// @dev Emits {StrategyChanged} event
    /// @param newStrategy new AAVE strategy address.
    function setAaveStrategy(address newStrategy) external;

    /// @notice Sets Compound stratedy address. Function available only for Owner.
    /// @dev Emits {StrategyChanged} event
    /// @param newStrategy new Compound strategy address.
    function setCompoundStrategy(address newStrategy) external;

    /// @notice Sets Milton address. Function available only for Owner.
    /// @dev Emits {MiltonChanged} event
    /// @newMilton new Milton address.
    function setMilton(address newMilton) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner.
    /// @dev Emits {Paused} event from Stanley.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Stanley.
    function unpause() external;

    /// @notice Emmited when all Stanley's assets migrated from old strategy to new one. Function available only by Owner.
    /// @param changedBy account address who executes migrations
    /// @param oldStrategy old strategy address where assets was before migration
    /// @param newStrategy new strategy address where assets was migrated
    /// @param amount final amount of assets which was migrated between strategies
    event AssetMigrated(
        address changedBy,
        address oldStrategy,
        address newStrategy,
        uint256 amount
    );

    /// @notice Emmited when stratedy address changed by smart contract Owner.
    /// @param changedBy account address who changed strategy address
    /// @param oldStrategy old strategy address
    /// @param newStrategy new strategy address
    /// @param shareToken strategy share token address
    event StrategyChanged(
        address changedBy,
        address oldStrategy,
        address newStrategy,
        address shareToken
    );

    /// @notice Emmited when Milton address changed by smart contract Owner.
    /// @param changedBy account address who changed Milton address
    /// @param oldMilton old Milton address
    /// @param newMilton new Milton address
    event MiltonChanged(address changedBy, address oldMilton, address newMilton);
}
