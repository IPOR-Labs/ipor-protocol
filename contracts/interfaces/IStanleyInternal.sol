// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Interface for interaction with Stanley smart contract - administration and maintenance part.
interface IStanleyInternal {
    /// @notice Returns current version of Stanley
	/// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current Stanley's version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Stanley instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets Milton address
    /// @return Milton address
    function getMilton() external view returns (address);

    function getIvToken() external view returns (address);

    /// @notice Gets Strategy Aave address
    /// @return Strategy Aave address
    function getStrategyAave() external view returns (address);

    /// @notice Gets Strategy Compound address
    /// @return Strategy Compound address
    function getStrategyCompound() external view returns (address);

    /// @notice Transfers all asset in current strategy to strategy with the highest APR. Function available only for the Owner.
    /// @dev Emits {Deposit} or {Withdraw} event from Stanley depending on current asset balance on Milton and Stanley. Emits {Transfer} from ERC20 asset.
    function migrateAssetToStrategyWithMaxApr() external;

    /// @notice Sets AAVE strategy address. Function available only for the Owner.
    /// @dev Emits {StrategyChanged} event
    /// @param newStrategy new AAVE strategy address.
    function setStrategyAave(address newStrategy) external;

    /// @notice Sets Compound strategy address. Function available only for the Owner.
    /// @dev Emits {StrategyChanged} event
    /// @param newStrategy new Compound strategy address.
    function setStrategyCompound(address newStrategy) external;

    /// @notice Sets Milton address. Function available only for the Owner.
    /// @dev Emits {MiltonChanged} event
    /// @param newMilton new Milton address.
    function setMilton(address newMilton) external;

    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from Stanley.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Stanley.
    function unpause() external;

    /// @notice Emmited when all Stanley's assets are migrated from old strategy to the new one. Function is available only by the Owner.
    /// @param changedBy account address that has executed migrations
    /// @param oldStrategy old strategy address where assets was before migration
    /// @param newStrategy new strategy address where assets was migrated
    /// @param amount final amount of assets which were migrated between strategies, represented in 18 decimals
    event AssetMigrated(
        address changedBy,
        address oldStrategy,
        address newStrategy,
        uint256 amount
    );

    /// @notice Emmited when stratedy address has been changed by the smart contract Owner.
    /// @param changedBy account address that has changed the strategy address
    /// @param oldStrategy old strategy address
    /// @param newStrategy new strategy address
    /// @param newShareToken strategy share token's address
    event StrategyChanged(
        address changedBy,
        address oldStrategy,
        address newStrategy,
        address newShareToken
    );

    /// @notice Emmited when Milton address has been changed by the smart contract Owner.
    /// @param changedBy account address that has changed Milton address
    /// @param oldMilton old Milton address
    /// @param newMilton new Milton address
    event MiltonChanged(address changedBy, address oldMilton, address newMilton);
}
