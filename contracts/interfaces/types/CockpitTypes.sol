// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Types used in comunication with Cockpit, an internal web application for IPOR Protocol diagnosis.
/// @dev used by ICockpitDataProvider interface
library CockpitTypes {
    /// @notice Struct which groups important addresses used in smart contract CockpitDataProvider,
    /// struct represent data for one specific asset which is USDT, USDC, DAI etc.
    struct AssetConfig {
        /// @notice Milton address
        address milton;
        /// @notice MiltonStorage address
        address miltonStorage;
        /// @notice Joseph address
        address joseph;
        /// @notice ipToken address (Liquidity Pool Token)
        address ipToken;
        /// @notice ivToken address (Ipor Vault Token)
        address ivToken;
    }

    /// @notice Structure used for representind IPOR Index data in Cockpit web application
    struct IporFront {
        /// @notice Asset Symbol like USDT, USDC, DAI etc. (in general stablecoins)
        string asset;
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice Interest Bearing Token Price
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
        /// @notice Exponential Moving Average
        /// @dev value represented in 18 decimals
        uint256 exponentialMovingAverage;
        /// @notice Exponential Weighted Moving Variance
        /// @dev value represented in 18 decimals
        uint256 exponentialWeightedMovingVariance;
        /// @notice Last update date of IPOR Index done by Charlie
        /// @dev value represented in 18 decimals
        uint256 lastUpdateTimestamp;
    }
}
