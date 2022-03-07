// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStanleyAdministration {
    function aaveBeforeClaim(address[] memory assets, uint256 amount) external;

    function aaveDoClaim(address account) external;

    function compoundDoClaim(address account) external;

    function migrateAssetToStrategyWithMaxApy() external;

    function setAaveStrategy(address strategyAddress) external;

    function setCompoundStrategy(address strategy) external;

    function setMilton(address milton) external;

    event MigrateAsset(
        address currentStrategy,
        address newStrategy,
        uint256 amount
    );

    event SetStrategy(address strategy, address shareToken);

    event DoClaim(address strategy, address account);
}
