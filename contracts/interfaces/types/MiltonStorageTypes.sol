// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Types used in MiltonStorage smart contract
library MiltonStorageTypes {
    /// @notice struct representing swap's ID and direction
    /// @dev direction = 0 - Pay Fixed ReceiveFloating, direction = 1 - Receive Fixed Pay Floating
    struct IporSwapId {
        /// @notice Swap ID
        uint256 id;
        /// @notice Swap direction, 0 - Pay Fixed Receive Floating, 1 - Receive Fixed Pay Floating
        uint8 direction;
    }

    /// @notice Struct containing extended balance information.
    /// @dev extended information includes: opening fee balance, liquidation deposit balance,
    /// IPOR publication fee balance, treasury balance, all balances are in 18 decimals
    struct ExtendedBalancesMemory {
<<<<<<< HEAD
        /// @notice Swaps balance for Pay Fixed leg
        uint256 payFixedTotalCollateral;
        /// @notice Swaps balance for Receive Fixed leg
        uint256 receiveFixedTotalCollateral;
        /// @notice Liquidity Pool Balance
        /// @dev Includes part of Opening Fee, how big percentage of total amount is taken as a opening fee
        /// is defined in param _OPENING_FEE_PERCENTAGE
=======
        /// @notice Sum of collaterals on Pay Fixed leg
        uint256 payFixedSwaps;
        /// @notice Sum of collaterals on Receive Fixed leg
        uint256 receiveFixedSwaps;
        /// @notice Liquidity pool balance
>>>>>>> 761cff5 (updated documenation)
        uint256 liquidityPool;
        /// @notice Stanley's (Asset Management) balance
        uint256 vault;
        /// @notice IPOR publication fee balance. Transfers from this balance to subsidize IPOR publications are allowed
        uint256 iporPublicationFee;
        /// @notice Balance of the DAO's treasury. Fed by portion of the opening and income fees set by the DAO
        uint256 treasury;
    }
}
