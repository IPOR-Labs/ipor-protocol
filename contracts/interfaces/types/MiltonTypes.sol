// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./IporTypes.sol";

/// @title Structs used in Milton smart contract
library MiltonTypes {
    /// @notice Swap direction (long = pay fixed and receive a floating or short = receive fixed and pay a floating)
    enum SwapDirection {
        /// @notice In long position the trader will pay a fixed rate and receive a floating rate.
        PAY_FIXED_RECEIVE_FLOATING,
        /// @notice In short position the trader will receive fixed rate and pay a floating rate.
        PAY_FLOATING_RECEIVE_FIXED
    }

    /// @notice Collection of Swap indicators corelated with IPOR Index for a specific asset
    /// @dev all values are in 18 decimals
    struct IporSwapIndicator {
        /// @notice IPOR Index value indicator
        uint256 iporIndexValue;
        /// @notice IPOR Interest Bearing Token price
        uint256 ibtPrice;
        /// @notice IPOR Interest Bearing Token quantity
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been locked (Refference leg +/- spread per leg),
        /// it is quote from spread documentation
        uint256 fixedInterestRate;
    }
}
