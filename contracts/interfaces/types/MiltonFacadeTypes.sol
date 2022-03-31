// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Structs used in comunication Darcy web application with Ipor Protocol
/// @dev structs used in IMiltonFacadeDataProvider and IWarrenFacadeDataProvider interfaces
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
        uint256 liquidityPool;
        uint256 payFixedTotalNotional;
        uint256 recFixedTotalNotional;
        uint256 payFixedTotalCollateral;
        uint256 recFixedTotalCollateral;
    }

    struct AssetConfiguration {
        address asset;
        uint256 minLeverageValue;
        uint256 maxLeverageValue;
        uint256 openingFeePercentage;
        uint256 iporPublicationFeeAmount;
        uint256 liquidationDepositAmount;
        uint256 incomeFeePercentage;
        uint256 spreadPayFixedValue;
        uint256 spreadRecFixedValue;
        uint256 maxLpUtilizationPercentage;
        uint256 maxLpUtilizationPerLegPercentage;
    }

    struct IporSwap {
        uint256 id;
        address asset;
        uint256 collateral;
        uint256 notionalAmount;
        uint256 leverage;
        uint8 direction;
        uint256 fixedInterestRate;
        int256 positionValue;
        uint256 openTimestamp;
        uint256 endTimestamp;
        uint256 liquidationDepositAmount;
    }
}
