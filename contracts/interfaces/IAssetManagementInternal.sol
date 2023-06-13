// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface for interaction with AssetManagement smart contract - administration and maintenance part.
interface IAssetManagementInternal {
    /// @notice Returns current version of AssetManagement
	/// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current AssetManagement's version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this AssetManagement instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets AmmTreasury address
    /// @return AmmTreasury address
    function getAmmTreasury() external view returns (address);

    /// @notice Gets IvToken address
    /// @return IvToken address
    function getIvToken() external view returns (address);

    /// @notice Gets Strategy Aave address
    /// @return Strategy Aave address
    function getStrategyAave() external view returns (address);

    /// @notice Gets Strategy Compound address
    /// @return Strategy Compound address
    function getStrategyCompound() external view returns (address);

    /// @notice Transfers all asset in current strategy to strategy with the highest APY. Function available only for the Owner.
    /// @dev Emits {Deposit} or {Withdraw} event from AssetManagement depending on current asset balance on AmmTreasury and AssetManagement. Emits {Transfer} from ERC20 asset.
    function migrateAssetToStrategyWithMaxApy() external;

    /// @notice Sets AAVE strategy address. Function available only for the Owner.
    /// @dev Emits {StrategyChanged} event
    /// @param newStrategy new AAVE strategy address.
    function setStrategyAave(address newStrategy) external;

    /// @notice Sets Compound strategy address. Function available only for the Owner.
    /// @dev Emits {StrategyChanged} event
    /// @param newStrategy new Compound strategy address.
    function setStrategyCompound(address newStrategy) external;

    /// @notice Sets AmmTreasury address. Function available only for the Owner.
    /// @dev Emits {AmmTreasuryChanged} event
    /// @param newAmmTreasury new AmmTreasury address.
    function setAmmTreasury(address newAmmTreasury) external;

    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from AssetManagement.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AssetManagement.
    function unpause() external;

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param _guardian The address of the pause guardian to be added.
    function addPauseGuardian(address _guardian) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param _guardian The address of the pause guardian to be removed.
    function removePauseGuardian(address _guardian) external;

    /// @notice Emmited when all AssetManagement's assets are migrated from old strategy to the new one. Function is available only by the Owner.
    /// @param newStrategy new strategy address where assets was migrated
    /// @param amount final amount of assets which were migrated between strategies, represented in 18 decimals
    event AssetMigrated(
        address newStrategy,
        uint256 amount
    );

    /// @notice Emitted when stratedy address has been changed by the smart contract Owner.
    /// @param newStrategy new strategy address
    /// @param newShareToken strategy share token's address
    event StrategyChanged(
        address newStrategy,
        address newShareToken
    );

    /// @notice Emmited when AmmTreasury address has been changed by the smart contract Owner.
    /// @param newAmmTreasury new AmmTreasury address
    event AmmTreasuryChanged(address newAmmTreasury);
}
