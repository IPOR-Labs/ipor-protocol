// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.15;

/// @title Structs used in comunication Darcy web application with Ipor Protocol
/// @dev structs used in IMiltonFacadeDataProvider and IIporOracleFacadeDataProvider interfaces
library MiltonFacadeTypes {
    /// @notice Technical struct which groups important addresses used in smart contract MiltonFacadeDataProvider,
    /// struct represent data for one specific asset which is USDT, USDC, DAI etc.
    struct AssetConfig {
        /// @notice Milton address
        address milton;
        /// @notice MiltonStorage address
        address miltonStorage;
        /// @notice Joseph address
        address joseph;
    }

    /// @notice Struct which groups Milton balances required for frontedn
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
        /// @notice Maximum leverage value. Represented in 18 decimals.
        uint256 maxLeverage;
        /// @notice Rate of collateral taken as a opening fee. Represented in 18 decimals.
        uint256 openingFeeRate;
        /// @notice IPOR publication fee amount taken from buyer when opening new swap. Represented in 18 decimals.
        uint256 iporPublicationFeeAmount;
        /// @notice Liquidation deposit amount take from buyer when opening new swap. Represented in 18 decimals.
        uint256 liquidationDepositAmount;
        /// @notice Rate of income taken from buyer when closing swap. Represented in 18 decimals.
        uint256 incomeFeeRate;
        /// @notice Calculated Spread for leg Pay Fixed - Receive Floating. Represented in 18 decimals.
        int256 spreadPayFixed;
        /// @notice Calculated Spread for leg Receive Fixed - Pay Floating. Represented in 18 decimals.
        int256 spreadReceiveFixed;
        /// @notice Maximum Liquidity Pool Utilization.
        /// @dev It is a ratio of total collateral balance / liquidity pool balance
        uint256 maxLpUtilizationRate;
        /// @notice Maximum Liquidity Pool Utilization per one leg.
        /// @dev It is a ratio of total collateral balance for one leg / liquidity pool balance
        uint256 maxLpUtilizationPerLegRate;
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
