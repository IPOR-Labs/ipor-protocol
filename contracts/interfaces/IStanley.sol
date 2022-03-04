// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStanley {
    //@notice return amount in stable
    function totalBalance(address who) external view returns (uint256);

    //@notice in return balance before deposit
    function deposit(uint256 amount) external returns (uint256 balance);

    //@notice withdraw specific amount of stable
    function withdraw(uint256 amount)
        external
        returns (uint256 withdrawnValue, uint256 balance);

    function withdrawAll() external;

    event SetStrategy(address strategy, address shareToken);

    event Deposit(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenValue
    );

    event Withdraw(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenValue
    );

    event MigrateAsset(
        address currentStrategy,
        address newStrategy,
        uint256 amount
    );
    event DoClaim(address strategyAddress, address _account);
}
