// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Stanley smart contract, which is reposnsible for investing Milton's assets.
interface IStanley {
    /// @notice Returns current version of Stanley's
    /// @return current Stanley version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Stanley instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets total balance of account `who`,  transferred to Stanley and earned by Stanley using external DeFi protocols.
    /// @param who Account for which total balance is returned.
    /// @return Total balance for specific account given as a parameter, represented in 18 decimals.
    function totalBalance(address who) external view returns (uint256);

    /// @notice Calculated exchange rate of ivToken for a given asset represented by Stanley's smart contract instance.
    /// @return Current exchange rate ivToken for a given asset, represented in 18 decimals.
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Deposits ERC20 underlying / stablecoin assets to Stanley. Function available only for Milton.
    /// @dev Emits {Deposit} event from Stanley, emits {Mint} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// @param amount deposited amount by Milton to Stanley
    /// @return vaultBalance current balance which includes also deposited amount on Stanley site.
    function deposit(uint256 amount) external returns (uint256 vaultBalance);

    /// @notice Withdraws specific amount of stable from Stanley to Milton. Function available only for Milton.
    /// @dev Emits {Withdraw} event from Stanley, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount deposited amount of underlying / stablecoin asset
    /// @return withdrawnAmount final withdrawn amount of asset from Stanley, can be different than input amount.
    /// @return vaultBalance current asset balance on Stanley site
    function withdraw(uint256 amount)
        external
        returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Withdraws all specific amount of stable from Stanley to Milton. Function available only for Milton.
    /// @dev Emits {Withdraw} event from Stanley, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Output values are represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of asset from Stanley.
    /// @return vaultBalance current asset balance on Stanley site
    function withdrawAll() external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Emmited when Milton execute deposit function.
    /// @param timestamp moment when deposit was executed
    /// @param from account address from assets amount is transferred to
    /// @param to account address where assets amount are transferred
    /// @param exchangeRate exchange rate of ivToken, represented in 18 decimals
    /// @param amount asset amount which is transferred from Milton to Stanley, represented in 18 decimals
    /// @param ivTokenAmount amount of ivToken calculated based on `exchangeRate` and `amount`, represented in 18 decimals.
    event Deposit(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenAmount
    );

    /// @notice Emmited when Milton execute withdraw function.
    /// @param timestamp moment when deposit was executed
    /// @param from account address from assets amount is transferred to
    /// @param to account address where assets amount are transferred
    /// @param exchangeRate exchange rate of ivToken, represented in 18 decimals
    /// @param amount asset amount which is transferred from Milton to Stanley, represented in 18 decimals
    /// @param ivTokenAmount amount of ivToken calculated based on `exchangeRate` and `amount`, represented in 18 decimals.
    event Withdraw(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenAmount
    );
}
