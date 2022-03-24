// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice Struct representing IPOR Index data related metrics.
    struct AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information reffer to the documentation: 
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
        /// @notice Exponential Moving Average
        /// @dev value represented in 18 decimals
        uint256 exponentialMovingAverage;
        /// @notice Exponential Weighted Moving Variance
        /// @dev value represented in 18 decimals
        uint256 exponentialWeightedMovingVariance;
    }

    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct IporSwapMemory {
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        uint256 state;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Epoch when the swap will reach it's maturity
        uint256 endTimestamp;
        /// @notice Swap's unique ID 
        uint256 id;
        /// @notice Index position of this Swap in array of swaps' identificators assocciated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array. 
        /// During removal the last item in the array is switched with the one that just have been removed. 
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notionalAmount;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct MiltonBalancesMemory {
        /// @notice Swaps total balance for Pay Fixed leg
        uint256 payFixedTotalCollateral;
        /// @notice Swaps total balance for Receive Fixed leg
        uint256 receiveFixedTotalCollateral;
        /// @notice Liquidity Pool Balance, includes part of Opening Fee,
        /// @ dev how much of Opening Fee is accounterd here is defined by param IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transfered to Asset Management Vault (Stanley)
        uint256 vault;
    }
}
