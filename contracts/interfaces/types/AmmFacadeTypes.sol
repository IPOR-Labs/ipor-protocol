// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Structs used in comunication Darcy web application with Ipor Protocol
/// @dev structs used in IAmmTreasuryFacadeDataProvider and IIporOracleFacadeDataProvider interfaces
library AmmFacadeTypes {
    /// @notice Technical struct which groups important addresses used in smart contract AmmTreasuryFacadeDataProvider,
    /// struct represent data for one specific asset which is USDT, USDC, DAI etc.
    struct AssetConfig {
        /// @notice AmmTreasury address
        address ammTreasury;
        /// @notice AmmStorage address
        address ammStorage;

    }

    /// @notice Struct which groups AmmTreasury balances required for frontedn
    struct Balance {
        /// @notice Liquiditiy Pool Balance. Represented in 18 decimals.
        uint256 liquidityPool;
        /// @notice Total notional for leg Pay Fixed - Receive Floating. Represented in 18 decimals.
        uint256 totalNotionalPayFixed;
        /// @notice Total notional for leg Receive Fixed - Pay Floating. Represented in 18 decimals.
        uint256 totalNotionalReceiveFixed;
        /// @notice Total collateral for leg Pay Fixed - Receive Floating. Represented in 18 decimals.
        uint256 totalCollateralPayFixed;
        /// @notice Total collateral for leg Receive Fixed - Pay Floating. Represented in 18 decimals.
        uint256 totalCollateralReceiveFixed;
    }

    /// @notice Struct describe configuration for one asset (stablecoin / underlying token).
    struct AssetConfiguration {
        /// @notice underlying token / stablecoin address
        address asset;
        /// @notice Minimal leverage value. Represented in 18 decimals.
        uint256 minLeverage;
        /// @notice Maximum swap leverage value. Represented in 18 decimals.
        uint256 maxLeverage;
        /// @notice Rate of collateral taken as a opening fee. Represented in 18 decimals.
        uint256 openingFeeRate;
        /// @notice IPOR publication fee amount taken from buyer when opening new swap. Represented in 18 decimals.
        uint256 iporPublicationFeeAmount;
        /// @notice Liquidation deposit amount take from buyer when opening new swap. Represented in 18 decimals.
        uint256 liquidationDepositAmount;
        /// @notice Calculated Spread. Represented in 18 decimals.
        int256 spread;
        /// @notice Maximum Liquidity Pool Utilization.
        /// @dev It is a ratio of total collateral balance / liquidity pool balance
        uint256 maxLpUtilizationRate;
        /// @notice Maximum amount which can be in Liquidity Pool, represented in 18 decimals.
        uint256 maxLiquidityPoolBalance;
        /// @notice Maximum amount which can be contributed by one account in Liquidity Pool, represented in 18 decimals.
        uint256 maxLpAccountContribution;
    }

    /// @notice IPOR Swap structure used by facades.
    struct IporSwap {
        /// @notice Swap ID.
        uint256 id;
        /// @notice Swap asset (stablecoint / underlying token)
        address asset;
        /// @notice Swap collateral, represented in 18 decimals.
        uint256 collateral;
        /// @notice Notional amount, represented in 18 decimals.
        uint256 notional;
        /// @notice Swap leverage, represented in 18 decimals.
        uint256 leverage;
        /// @notice Swap direction
        /// @dev 0 - Pay Fixed-Receive Floating, 1 - Receive Fixed - Pay Floading
        uint8 direction;
        /// @notice Fixed interest rate.
        uint256 fixedInterestRate;
        /// @notice Current position value, represented in 18 decimals.
        int256 payoff;
        /// @notice Moment when swap was opened.
        uint256 openTimestamp;
        /// @notice Mopment when swap achieve its maturity.
        uint256 endTimestamp;
        /// @notice Liqudidation deposit value on day when swap was opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
    }
}
