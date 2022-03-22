// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Types used in comunication with Cockpit - an internal web responsible for IPOR Protocol diagnosis and monitoring.
/// @dev used by ICockpitDataProvider interface
library CockpitTypes {
    /// @notice Struct groupping important addresses used by CockpitDataProvider,
    /// struct represent data for a specific asset ie. USDT, USDC, DAI etc.
    struct AssetConfig {
        /// @notice Milton (AMM) address
        address milton;
        /// @notice MiltonStorage address
        address miltonStorage;
        /// @notice Joseph (part of AMM responsible for Liquidity Pool management) address
        address joseph;
        /// @notice ipToken address (Liquidity Pool Token)
        address ipToken;
        /// @notice ivToken address (IPOR Vault Token)
        address ivToken;
    }

    /// @notice Structure used to represent IPOR Index data in Cockpit web app
    struct IporFront {
        /// @notice Asset Symbol ie. USDT, USDC, DAI etc. 
        string asset;
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice Interest Bearing Token (IBT) Price
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
        /// @notice Exponential Moving Average 
        /// @dev value represented in 18 decimals
        uint256 exponentialMovingAverage;
        /// @notice Exponential Weighted Moving Variance
        /// @dev value represented in 18 decimals
        uint256 exponentialWeightedMovingVariance;
        /// @notice Epoch timestamp of most recent IPOR publication
        /// @dev value represented in 18 decimals
        uint256 lastUpdateTimestamp;
    }
}
