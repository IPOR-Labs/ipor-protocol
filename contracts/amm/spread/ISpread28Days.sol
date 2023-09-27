// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../interfaces/types/IporTypes.sol";

/// @title Spread interface for tenor 28 days service
interface ISpread28Days {
    /// @notice Calculates the quote value for pay fixed 28-day period based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value.
    function calculateAndUpdateOfferedRatePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value to receive fixed 28-day period based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value to receive.
    function calculateAndUpdateOfferedRateReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}
