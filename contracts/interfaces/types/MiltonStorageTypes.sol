// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Types used in MiltonStorage smart contract
library MiltonStorageTypes {
    /// @notice struct which represent Swap Id and Swap direction for a specific asset
    /// @dev direction = 0 - Pay Fixed Receive Floating Swap, direction = 1 - Receive Fixed Pay Floating Swap
    struct IporSwapId {
        /// @notice Swap ID
        uint256 id;
        /// @notice Swap direction, 0 - Pay Fixed Receive Floating, 1 - Receive Fixed Pay Floating
        uint8 direction;
    }

    /// @notice Struct which contains extended balance information.
    /// @dev extended information are Opening Fee Balance, Liuidation Deposit Balance,
    /// Ipor Publication Fee Balance, Treasury Balance, all balances in 18 decimals
    struct ExtendedBalancesMemory {
        /// @notice Swaps balance for Pay Fixed leg
        uint256 payFixedSwaps;
        /// @notice Swaps balance for Receive Fixed leg
        uint256 receiveFixedSwaps;
        /// @notice Liquidity Pool Balance
        /// @dev Includes part of Opening Fee, how big percentage of total amount is taken as a opening fee
        /// is defined in param _OPENING_FEE_PERCENTAGE
        uint256 liquidityPool;
        /// @notice Actual Balance on Stanley (Asset Management) site vault
        uint256 vault;
        /// @notice Ipor Publication Fee Balance, intended for Charlie off-chain service for
        /// oracle which need cash for updating IPOR Index
        uint256 iporPublicationFee;
        /// @notice income fee goes here, part of opening fee also goes here,
        /// how many of Opening Fee goes here is configured in constant _OPENING_FEE_FOR_TREASURY_PERCENTAGE
        uint256 treasury;
    }
}
