// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Interface for interaction with Stanley DSR smart contract.
/// @notice Stanley is responsible for delegating assets stored in Milton to Asset Management and forward to money market where they can earn interest.
interface IStanleyDsr {
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

    /// @notice Gets IvToken address
    /// @return IvToken address
    function getIvToken() external view returns (address);

    /// @notice Gets total balance of Milton (AmmTreasury), transferred assets to Stanley.
    /// @return Total balance for specific account given as a parameter, represented in 18 decimals.
    function totalBalance(address who) external view returns (uint256);

    /// @notice Calculated exchange rate between ivToken and the underlying asset.
    /// @return Current exchange rate between ivToken and the underlying asset, represented in 18 decimals.
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Deposits ERC20 underlying assets to Stanley. Function available only for Milton.
    /// @dev Emits {Deposit} event from Stanley, emits {Mint} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount amount deposited by Milton to Stanley.
    /// @return vaultBalance current balance including amount deposited on Stanley.
    /// @return depositedAmount final deposited amount.
    function deposit(uint256 amount)
        external
        returns (uint256 vaultBalance, uint256 depositedAmount);

    /// @notice Withdraws declared amount of asset from Stanley to Milton. Function available only for Milton.
    /// @dev Emits {Withdraw} event from Stanley, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount deposited amount of underlying asset
    /// @return withdrawnAmount final withdrawn amount of asset from Stanley, can be different than input amount due to passing time.
    /// @return vaultBalance current asset balance on Stanley
    function withdraw(uint256 amount)
        external
        returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Withdraws all of the asset from Stanley to Milton. Function available only for Milton.
    /// @dev Emits {Withdraw} event from Stanley, emits {Burn} event from ivToken, emits {Transfer} event from ERC20 asset.
    /// Output values are represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of the asset.
    /// @return vaultBalance current asset's balance on Stanley
    function withdrawAll() external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Gets Strategy Aave address
    /// @return Strategy Aave address
    function getStrategyAave() external view returns (address);

    /// @notice Gets Strategy Compound address
    /// @return Strategy Compound address
    function getStrategyCompound() external view returns (address);

    /// @notice Gets Strategy Dai Savings Rate address
    /// @return Strategy DSR address
    function getStrategyDsr() external view returns (address);

    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from Stanley.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Stanley.
    function unpause() external;

    /// @notice Emitted after Milton has executed deposit function.
    /// @param timestamp moment when deposit function was executed
    /// @param from account address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param exchangeRate exchange rate of ivToken, represented in 18 decimals
    /// @param amount of asset transferred from Milton to Stanley, represented in 18 decimals
    /// @param ivTokenAmount amount calculated based on `exchangeRate` and `amount`, represented in 18 decimals.
    event Deposit(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 amount,
        uint256 ivTokenAmount
    );

    /// @notice Emitted when Milton executes withdraw function.
    /// @param timestamp moment when deposit was executed
    /// @param from strategy address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param exchangeRate exchange rate of ivToken, represented in 18 decimals
    /// @param amount of asset transferred from Milton to Stanley, represented in 18 decimals
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
