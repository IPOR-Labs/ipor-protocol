// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Struct used across many interfaces in IPOR Protocol.
library IporTypes {
    /// @notice Struct represent IPOR Index data with additional accrual from last update date to current date
    struct AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token)
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
        /// @notice Exponential Moving Average
        /// @dev value represented in 18 decimals
        uint256 exponentialMovingAverage;
        /// @notice Exponential Weighted Moving Variance
        /// @dev value represented in 18 decimals
        uint256 exponentialWeightedMovingVariance;
    }

    /// @notice Struct represented Swap item, used in listing and internal calculations
    struct IporSwapMemory {
        /// @ notice state of the Swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        uint256 state;
        /// @notice Buyer of this Swap
        address buyer;
        /// @notice Moment when Swap was opened
        uint256 openTimestamp;
        /// @notice Moment when Swap will achieve maturity and can be closed by anyone
        uint256 endTimestamp;
        /// @notice unique ID of this Swap
        uint256 id;
        /// @notice index position of this Swap in array of Swap identificators assocciated to Swap creator
        /// @dev field used for gas optimization purposes, which allow to fast remove id in array
        /// making swap between last id in array and id represented by value idsIndex
        uint256 idsIndex;
        /// @notice Collateral used in Swap
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Liquidation Deposit Amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Notional Principal Amount of this Swap
        /// @dev value represented in 18 decimals
        uint256 notionalAmount;
        /// @notice Fixed interest rate at which the position has been locked
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Interest Bearing Token Quantity
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
    }

    /// @notice Struct represents required balances used internally for calculations per one asset
    /// @dev all balances in 18 decimals
    struct MiltonBalancesMemory {
        /// @notice Swaps total balance for Pay Fixed leg
        uint256 payFixedTotalCollateral;
        /// @notice Swaps total balance for Receive Fixed leg
        uint256 receiveFixedTotalCollateral;
        /// @notice Liquidity Pool Balance includes part of Opening Fee,
        /// @ dev how many of Opening Fee goes here is defined by param IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 liquidityPool;
        /// @notice Vault balance, describe how many asset balance is transferred to Asset Management Vault (Stanley)
        uint256 vault;
    }
}
