// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStanleyAdministration {
    function migrateAssetToStrategyWithMaxApy() external;

    function setAaveStrategy(address strategyAddress) external;

    function setCompoundStrategy(address strategy) external;

    function setMilton(address milton) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Stanley.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Stanley.
    function unpause() external;

    event MigrateAsset(address currentStrategy, address newStrategy, uint256 amount);

    event SetStrategy(address strategy, address shareToken);

    event DoClaim(address strategy, address account);
}
