// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @notice Structs used in the AmmStorage interface
library StorageTypesGenOne {
    /// @notice A struct containing balances that AMM keeps track of. It acts as a AMM's accounting book.
    /// Those balances are used in various calculations across the protocol.
    /// @dev All balances are in 18 decimals
    struct Balance {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint128 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint128 totalCollateralReceiveFixed;
        /// @notice This balance is used to track the funds accounted for IporOracle subsidization.
        uint128 iporPublicationFee;
        /// @notice Treasury is the balance that belongs to IPOR DAO and funds up to this amount can be transferred to the DAO-appointed multi-sig wallet.
        /// this ballance is fed by part of the opening fee appointed by the DAO. For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps#fees
        uint128 treasury;
    }
}
